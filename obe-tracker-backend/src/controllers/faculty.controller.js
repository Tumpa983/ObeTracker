const prisma = require('../prisma');
const { computeCOAttainment, computePOAttainment } = require('../utils/attainment');

// ── My Courses ───────────────────────────────────────────────
const getMyCourses = async (req, res, next) => {
  try {
    const { userId, role, institutionId } = req.user;
    const where = {
      deletedAt: null,
      program: { department: { institutionId } },
      ...(role !== 'ADMIN' && { assignments: { some: { facultyId: userId } } }),
    };
    const courses = await prisma.course.findMany({
      where,
      include: {
        program: { select: { name: true, code: true } },
        session: { select: { name: true, status: true } },
        assignments: { include: { faculty: { select: { id: true, firstName: true, lastName: true, email: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ status: 'success', data: courses });
  } catch (err) { next(err); }
};

// ── Course Outcomes (include PO mappings) ────────────────────
const getCourseOutcomes = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const items = await prisma.courseOutcome.findMany({
      where: { courseId, deletedAt: null },
      include: {
        mappings: {
          include: { programOutcome: { select: { id: true, code: true, title: true } } },
        },
      },
      orderBy: { code: 'asc' },
    });
    res.json({ status: 'success', data: items });
  } catch (err) { next(err); }
};

const createCourseOutcome = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { code, title, description, bloomDomain, bloomLevel, profileType, profileCode } = req.body;
    // Check for duplicate code in this course
    const existing = await prisma.courseOutcome.findFirst({
      where: { courseId, code, deletedAt: null },
    });
    if (existing) {
      return res.status(409).json({ status: 'error', error: `CO code "${code}" already exists in this course.` });
    }
    const item = await prisma.courseOutcome.create({
      data: { courseId, code, title, description, bloomDomain, bloomLevel, profileType, profileCode },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteCourseOutcome = async (req, res, next) => {
  try {
    const { courseId, id } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const hasMapping = await prisma.coPoMapping.findFirst({ where: { courseOutcomeId: id } });
    const hasAssessment = await prisma.assessmentCO.findFirst({ where: { courseOutcomeId: id } });
    if (hasMapping || hasAssessment) {
      return res.status(409).json({ status: 'error', error: 'CO has mappings or assessments. Remove those first.' });
    }
    await prisma.courseOutcome.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'CO removed' } });
  } catch (err) { next(err); }
};

// ── CO-PO Mapping (simple list, no matrix) ───────────────────
const getMapping = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    const [cos, pos, mappings] = await Promise.all([
      prisma.courseOutcome.findMany({ where: { courseId, deletedAt: null }, orderBy: { code: 'asc' } }),
      prisma.programOutcome.findMany({
        where: { program: { courses: { some: { id: courseId } } }, deletedAt: null },
        orderBy: { code: 'asc' },
      }),
      prisma.coPoMapping.findMany({ where: { courseId } }),
    ]);
    const numSort = (a, b) => {
      const nA = parseInt(a.code.replace(/\D+/g, ''), 10);
      const nB = parseInt(b.code.replace(/\D+/g, ''), 10);
      return isNaN(nA) || isNaN(nB) ? a.code.localeCompare(b.code) : nA - nB;
    };
    cos.sort(numSort); pos.sort(numSort);
    res.json({ status: 'success', data: { courseOutcomes: cos, programOutcomes: pos, mappings } });
  } catch (err) { next(err); }
};

const saveMapping = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { mappings } = req.body;
    const existing = await prisma.coPoMapping.findFirst({ where: { courseId }, orderBy: { version: 'desc' } });
    const nextVersion = (existing?.version || 0) + 1;
    await prisma.$transaction(
      mappings.map(({ courseOutcomeId, programOutcomeId, correlation }) =>
        prisma.coPoMapping.upsert({
          where: { courseId_courseOutcomeId_programOutcomeId: { courseId, courseOutcomeId, programOutcomeId } },
          create: { courseId, courseOutcomeId, programOutcomeId, correlation: correlation || null, version: nextVersion },
          update: { correlation: correlation || null, version: nextVersion },
        })
      )
    );
    await recomputeAttainmentForCourse(courseId, nextVersion, req.user.institutionId);
    res.json({ status: 'success', data: { message: 'Mapping saved', version: nextVersion } });
  } catch (err) { next(err); }
};

// ── Assessments (no weight, just totalMarks and CO links) ─────
const getAssessments = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    const items = await prisma.assessment.findMany({
      where: { courseId, deletedAt: null },
      include: {
        assessmentCOs: {
          include: { courseOutcome: { select: { id: true, code: true, title: true } } },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
    res.json({ status: 'success', data: { assessments: items } });
  } catch (err) { next(err); }
};

const createAssessment = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { type, title, totalMarks, courseOutcomeIds } = req.body;
    const item = await prisma.assessment.create({
      data: {
        courseId, type, title,
        totalMarks: parseFloat(totalMarks),
        weight: 0, // weight removed from UI but field exists in schema
        assessmentCOs: { create: (courseOutcomeIds || []).map(coId => ({ courseOutcomeId: coId })) },
      },
      include: { assessmentCOs: true },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteAssessment = async (req, res, next) => {
  try {
    const { courseId, id } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const hasMarks = await prisma.mark.findFirst({ where: { assessmentId: id } });
    if (hasMarks) return res.status(409).json({ status: 'error', error: 'Assessment has marks and cannot be deleted.' });
    await prisma.assessment.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'Assessment deleted' } });
  } catch (err) { next(err); }
};

// ── Marks ────────────────────────────────────────────────────
const getMarks = async (req, res, next) => {
  try {
    const { assessmentId } = req.params;
    const assessment = await prisma.assessment.findUnique({
      where: { id: assessmentId },
      select: { courseId: true, totalMarks: true },
    });
    if (!assessment) return res.status(404).json({ status: 'error', error: 'Assessment not found' });

    const enrolments = await prisma.enrolment.findMany({
      where: { courseId: assessment.courseId },
      select: { studentId: true },
    });
    const studentIds = enrolments.map(e => e.studentId);

    const students = await prisma.user.findMany({
      where: { id: { in: studentIds } },
      select: { id: true, firstName: true, lastName: true, institutionalId: true },
      orderBy: { institutionalId: 'asc' },
    });

    const existingMarks = await prisma.mark.findMany({ where: { assessmentId } });
    const markMap = Object.fromEntries(existingMarks.map(m => [m.studentId, m.marksObtained]));

    const data = students.map(s => ({
      studentId:       s.id,
      institutionalId: s.institutionalId || '',
      name:            `${s.firstName} ${s.lastName}`,
      marksObtained:   markMap[s.id] ?? null,
    }));

    res.json({ status: 'success', data });
  } catch (err) { next(err); }
};

const saveMarks = async (req, res, next) => {
  try {
    const { assessmentId } = req.params;
    const { marks } = req.body;
    const assessment = await prisma.assessment.findUnique({ where: { id: assessmentId } });
    if (!assessment) return res.status(404).json({ status: 'error', error: 'Assessment not found' });

    const invalid = marks.filter(m => m.marksObtained < 0 || m.marksObtained > assessment.totalMarks);
    if (invalid.length) {
      return res.status(400).json({ status: 'error', error: `Marks out of range [0, ${assessment.totalMarks}]` });
    }

    const prevMarks = await prisma.mark.findMany({ where: { assessmentId } });
    const prevMap = Object.fromEntries(prevMarks.map(m => [m.studentId, m.marksObtained]));

    await prisma.$transaction([
      ...marks.map(({ studentId, marksObtained }) =>
        prisma.mark.upsert({
          where: { assessmentId_studentId: { assessmentId, studentId } },
          create: { assessmentId, studentId, marksObtained },
          update: { marksObtained },
        })
      ),
      ...marks
        .filter(m => prevMap[m.studentId] !== m.marksObtained)
        .map(m => prisma.markAuditLog.create({
          data: {
            assessmentId, studentId: m.studentId,
            changedById: req.user.userId,
            beforeValue: prevMap[m.studentId] ?? null,
            afterValue: m.marksObtained,
          },
        })),
    ]);

    await recomputeAttainmentForCourse(assessment.courseId, null, req.user.institutionId);
    res.json({ status: 'success', data: { message: `${marks.length} marks saved` } });
  } catch (err) { next(err); }
};

// ── Attainment (% of students who attained each CO/PO) ───────
const getCourseAttainment = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);

    const coRaw = await prisma.coAttainment.findMany({
      where: { courseId },
      include: { courseOutcome: { select: { code: true, title: true } } },
    });
    const poRaw = await prisma.poAttainment.findMany({
      where: { courseId },
      include: { programOutcome: { select: { code: true, title: true } } },
    });

    // Group by CO/PO and compute % of students who attained
    const coMap = {};
    coRaw.forEach(r => {
      if (!coMap[r.courseOutcomeId]) coMap[r.courseOutcomeId] = { co: r.courseOutcome, attained: 0, total: 0 };
      coMap[r.courseOutcomeId].total++;
      if (r.level === 'L3') coMap[r.courseOutcomeId].attained++;
    });
    const poMap = {};
    poRaw.forEach(r => {
      if (!poMap[r.programOutcomeId]) poMap[r.programOutcomeId] = { po: r.programOutcome, attained: 0, total: 0 };
      poMap[r.programOutcomeId].total++;
      if (r.level === 'L3') poMap[r.programOutcomeId].attained++;
    });

    const coSummary = Object.values(coMap).map(({ co, attained, total }) => ({
      code: co.code, title: co.title,
      attainedCount: attained, totalStudents: total,
      attainmentRate: total ? (attained / total * 100) : 0,
    }));
    const poSummary = Object.values(poMap).map(({ po, attained, total }) => ({
      code: po.code, title: po.title,
      attainedCount: attained, totalStudents: total,
      attainmentRate: total ? (attained / total * 100) : 0,
    }));

    // Sort numerically
    const numSort = (a, b) => {
      const nA = parseInt(a.code.replace(/\D+/g, ''), 10);
      const nB = parseInt(b.code.replace(/\D+/g, ''), 10);
      return isNaN(nA) || isNaN(nB) ? a.code.localeCompare(b.code) : nA - nB;
    };
    coSummary.sort(numSort); poSummary.sort(numSort);

    res.json({ status: 'success', data: { coSummary, poSummary } });
  } catch (err) { next(err); }
};

// ── Recompute ────────────────────────────────────────────────
async function recomputeAttainmentForCourse(courseId, matrixVersion, institutionId) {
  const enrolments = await prisma.enrolment.findMany({ where: { courseId } });
  if (!enrolments.length) return;

  if (!matrixVersion) {
    const latest = await prisma.coPoMapping.findFirst({ where: { courseId }, orderBy: { version: 'desc' } });
    matrixVersion = latest?.version || 1;
  }

  const cos = await prisma.courseOutcome.findMany({ where: { courseId, deletedAt: null } });
  const assessments = await prisma.assessment.findMany({
    where: { courseId, deletedAt: null },
    include: { assessmentCOs: true, marks: true },
  });
  const mappings = await prisma.coPoMapping.findMany({ where: { courseId } });
  const poIds = [...new Set(mappings.map(m => m.programOutcomeId))];

  const coUpdates = [], poUpdates = [];

  for (const enrolment of enrolments) {
    const studentId = enrolment.studentId;
    const coAttainmentMap = {};

    for (const co of cos) {
      const result = computeCOAttainment(studentId, co, assessments);
      if (!result) continue;
      coAttainmentMap[co.id] = result;
      coUpdates.push(prisma.coAttainment.upsert({
        where: { courseOutcomeId_studentId: { courseOutcomeId: co.id, studentId } },
        create: { courseOutcomeId: co.id, studentId, courseId, percentage: result.percentage, level: result.level, matrixVersion },
        update: { percentage: result.percentage, level: result.level, matrixVersion, computedAt: new Date() },
      }));
    }

    for (const poId of poIds) {
      const result = computePOAttainment(coAttainmentMap, mappings, poId);
      if (!result) continue;
      poUpdates.push(prisma.poAttainment.upsert({
        where: { programOutcomeId_studentId_courseId: { programOutcomeId: poId, studentId, courseId } },
        create: { programOutcomeId: poId, studentId, courseId, percentage: result.percentage, level: result.level, matrixVersion },
        update: { percentage: result.percentage, level: result.level, matrixVersion, computedAt: new Date() },
      }));
    }
  }

  const BATCH = 50;
  for (let i = 0; i < coUpdates.length; i += BATCH) await prisma.$transaction(coUpdates.slice(i, i + BATCH));
  for (let i = 0; i < poUpdates.length; i += BATCH) await prisma.$transaction(poUpdates.slice(i, i + BATCH));
}

async function assertFacultyOwns(user, courseId) {
  if (user.role === 'ADMIN') return;
  const a = await prisma.courseAssignment.findFirst({ where: { courseId, facultyId: user.userId } });
  if (!a) { const e = new Error('Not assigned to this course'); e.status = 403; throw e; }
}

module.exports = {
  getMyCourses,
  getCourseOutcomes, createCourseOutcome, deleteCourseOutcome,
  getMapping, saveMapping,
  getAssessments, createAssessment, deleteAssessment,
  getMarks, saveMarks,
  getCourseAttainment,
  recomputeAttainmentForCourse,
};
