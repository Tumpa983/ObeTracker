const prisma = require('../prisma');
const { computeCOAttainment, computePOAttainment, correlationWeight } = require('../utils/attainment');

// ── My Assigned Courses ──────────────────────────────────────
const getMyCourses = async (req, res, next) => {
  try {
    const { userId, role, institutionId } = req.user;

    // Admins see all courses in the institution; faculty see only assigned ones
    const where = {
      deletedAt: null,
      program: { department: { institutionId } },
      ...(role !== 'ADMIN' && {
        assignments: { some: { facultyId: userId } },
      }),
    };

    const courses = await prisma.course.findMany({
      where,
      include: {
        program: { select: { name: true, code: true } },
        session: { select: { name: true, status: true } },
        assignments: {
          include: {
            faculty: { select: { id: true, firstName: true, lastName: true, email: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ status: 'success', data: courses });
  } catch (err) { next(err); }
};

// ── Course Outcomes ──────────────────────────────────────────
const getCourseOutcomes = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const items = await prisma.courseOutcome.findMany({
      where: { courseId, deletedAt: null },
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
    const item = await prisma.courseOutcome.create({
      data: { courseId, code, title, description, bloomDomain, bloomLevel, profileType, profileCode },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateCourseOutcome = async (req, res, next) => {
  try {
    const { courseId, id } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { code, title, description, bloomDomain, bloomLevel, profileType, profileCode } = req.body;
    const item = await prisma.courseOutcome.update({
      where: { id },
      data: { code, title, description, bloomDomain, bloomLevel, profileType, profileCode },
    });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteCourseOutcome = async (req, res, next) => {
  try {
    const { courseId, id } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const hasMapping = await prisma.coPoMapping.findFirst({ where: { courseOutcomeId: id } });
    const hasAssessment = await prisma.assessmentCO.findFirst({ where: { courseOutcomeId: id } });
    if (hasMapping || hasAssessment) {
      return res.status(409).json({ status: 'error', error: 'CO is referenced by a mapping or assessment. Remove references first.' });
    }
    await prisma.courseOutcome.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'CO deactivated' } });
  } catch (err) { next(err); }
};

// ── CO-PO Mapping Matrix ─────────────────────────────────────
const getMapping = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    const [cos, pos, mappings] = await Promise.all([
      prisma.courseOutcome.findMany({ where: { courseId, deletedAt: null } }),
      prisma.programOutcome.findMany({
        where: { program: { courses: { some: { id: courseId } } }, deletedAt: null },
      }),
      prisma.coPoMapping.findMany({ where: { courseId } }),
    ]);

    // Sort numerically: CO1, CO2, ..., CO10 and PO1, PO2, ..., PO12
    const numSort = (a, b) => {
      const nA = parseInt(a.code.replace(/\D+/g, ''), 10);
      const nB = parseInt(b.code.replace(/\D+/g, ''), 10);
      if (!isNaN(nA) && !isNaN(nB)) return nA - nB;
      return a.code.localeCompare(b.code);
    };
    cos.sort(numSort);
    pos.sort(numSort);
    res.json({ status: 'success', data: { courseOutcomes: cos, programOutcomes: pos, mappings } });
  } catch (err) { next(err); }
};

const saveMapping = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { mappings } = req.body; // [{ courseOutcomeId, programOutcomeId, correlation }]

    // Get current version
    const existing = await prisma.coPoMapping.findFirst({ where: { courseId }, orderBy: { version: 'desc' } });
    const nextVersion = (existing?.version || 0) + 1;

    // Upsert each cell
    await prisma.$transaction(
      mappings.map(({ courseOutcomeId, programOutcomeId, correlation }) =>
        prisma.coPoMapping.upsert({
          where: { courseId_courseOutcomeId_programOutcomeId: { courseId, courseOutcomeId, programOutcomeId } },
          create: { courseId, courseOutcomeId, programOutcomeId, correlation: correlation || null, version: nextVersion },
          update: { correlation: correlation || null, version: nextVersion },
        })
      )
    );

    // Trigger recomputation
    await recomputeAttainmentForCourse(courseId, nextVersion, req.user.institutionId);

    res.json({ status: 'success', data: { message: 'Mapping saved', version: nextVersion } });
  } catch (err) { next(err); }
};

// ── Assessments ──────────────────────────────────────────────
const getAssessments = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    const items = await prisma.assessment.findMany({
      where: { courseId, deletedAt: null },
      include: { assessmentCOs: { include: { courseOutcome: { select: { id: true, code: true, title: true } } } } },
    });
    // Compute weight sum warning
    const weightSum = items.reduce((s, a) => s + a.weight, 0);
    res.json({ status: 'success', data: { assessments: items, weightSum, weightWarning: Math.abs(weightSum - 100) > 0.01 } });
  } catch (err) { next(err); }
};

const createAssessment = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { type, title, totalMarks, weight, courseOutcomeIds } = req.body;
    const item = await prisma.assessment.create({
      data: {
        courseId, type, title, totalMarks, weight,
        assessmentCOs: {
          create: (courseOutcomeIds || []).map(coId => ({ courseOutcomeId: coId })),
        },
      },
      include: { assessmentCOs: true },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateAssessment = async (req, res, next) => {
  try {
    const { courseId, id } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const { type, title, totalMarks, weight, courseOutcomeIds } = req.body;
    const hasMarks = await prisma.mark.findFirst({ where: { assessmentId: id } });
    if (hasMarks && (totalMarks !== undefined || courseOutcomeIds !== undefined)) {
      const { confirmed } = req.body;
      if (!confirmed) {
        return res.status(409).json({ status: 'error', error: 'Marks exist. Send confirmed:true to proceed.', requiresConfirmation: true });
      }
    }
    // Update CO mappings
    if (courseOutcomeIds !== undefined) {
      await prisma.assessmentCO.deleteMany({ where: { assessmentId: id } });
      await prisma.assessmentCO.createMany({
        data: courseOutcomeIds.map(coId => ({ assessmentId: id, courseOutcomeId: coId })),
        skipDuplicates: true,
      });
    }
    const item = await prisma.assessment.update({
      where: { id },
      data: { type, title, ...(totalMarks !== undefined && { totalMarks }), ...(weight !== undefined && { weight }) },
      include: { assessmentCOs: true },
    });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteAssessment = async (req, res, next) => {
  try {
    const { courseId, id } = req.params;
    await assertFacultyOwns(req.user, courseId);
    const hasMarks = await prisma.mark.findFirst({ where: { assessmentId: id } });
    if (hasMarks) return res.status(409).json({ status: 'error', error: 'Assessment has recorded marks and cannot be deleted.' });
    await prisma.assessment.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'Assessment deleted' } });
  } catch (err) { next(err); }
};

// ── Marks ────────────────────────────────────────────────────
const getMarks = async (req, res, next) => {
  try {
    const { assessmentId } = req.params;

    // Get the assessment to find its course
    const assessment = await prisma.assessment.findUnique({
      where: { id: assessmentId },
      select: { courseId: true },
    });
    if (!assessment) return res.status(404).json({ status: 'error', error: 'Assessment not found' });

    // Step 1: get all enrolled student IDs for this course
    const enrolments = await prisma.enrolment.findMany({
      where: { courseId: assessment.courseId },
      select: { studentId: true },
    });
    const studentIds = enrolments.map(e => e.studentId);

    // Step 2: fetch user details for those students
    const students = await prisma.user.findMany({
      where: { id: { in: studentIds } },
      select: { id: true, firstName: true, lastName: true, institutionalId: true, email: true },
      orderBy: { institutionalId: 'asc' },
    });

    // Step 3: get existing marks
    const existingMarks = await prisma.mark.findMany({ where: { assessmentId } });
    const markMap = Object.fromEntries(existingMarks.map(m => [m.studentId, m.marksObtained]));

    // Step 4: merge — every enrolled student gets a row
    const data = students.map(s => ({
      studentId:       s.id,
      institutionalId: s.institutionalId || s.email,
      name:            `${s.firstName} ${s.lastName}`,
      marksObtained:   markMap[s.id] ?? null,
    }));

    res.json({ status: 'success', data });
  } catch (err) { next(err); }
};

const saveMarks = async (req, res, next) => {
  try {
    const { assessmentId } = req.params;
    const { marks } = req.body; // [{ studentId, marksObtained }]
    const assessment = await prisma.assessment.findUnique({ where: { id: assessmentId } });
    if (!assessment) return res.status(404).json({ status: 'error', error: 'Assessment not found' });

    // Validate range
    const invalid = marks.filter(m => m.marksObtained < 0 || m.marksObtained > assessment.totalMarks);
    if (invalid.length) {
      return res.status(400).json({ status: 'error', error: `Marks out of range [0, ${assessment.totalMarks}]`, invalid });
    }

    // Get previous marks for audit
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
      // Audit log
      ...marks
        .filter(m => prevMap[m.studentId] !== m.marksObtained)
        .map(m =>
          prisma.markAuditLog.create({
            data: {
              assessmentId, studentId: m.studentId,
              changedById: req.user.userId,
              beforeValue: prevMap[m.studentId] ?? null,
              afterValue: m.marksObtained,
            },
          })
        ),
    ]);

    // Trigger attainment recomputation
    await recomputeAttainmentForCourse(assessment.courseId, null, req.user.institutionId);

    res.json({ status: 'success', data: { message: `${marks.length} marks saved` } });
  } catch (err) { next(err); }
};

// ── Attainment View ──────────────────────────────────────────
const getCourseAttainment = async (req, res, next) => {
  try {
    const { courseId } = req.params;
    await assertFacultyOwns(req.user, courseId);

    const [coAttainments, poAttainments] = await Promise.all([
      prisma.coAttainment.findMany({
        where: { courseId },
        include: { courseOutcome: { select: { code: true, title: true, bloomDomain: true, bloomLevel: true, profileType: true, profileCode: true } } },
      }),
      prisma.poAttainment.findMany({
        where: { courseId },
        include: { programOutcome: { select: { code: true, title: true } } },
      }),
    ]);

    res.json({ status: 'success', data: { coAttainments, poAttainments } });
  } catch (err) { next(err); }
};

// ── Helpers ──────────────────────────────────────────────────
async function assertFacultyOwns(user, courseId) {
  if (user.role === 'ADMIN') return; // Admins bypass
  const assignment = await prisma.courseAssignment.findFirst({
    where: { courseId, facultyId: user.userId },
  });
  if (!assignment) {
    const err = new Error('You are not assigned to this course');
    err.status = 403;
    throw err;
  }
}

async function recomputeAttainmentForCourse(courseId, matrixVersion, institutionId) {
  const enrolments = await prisma.enrolment.findMany({ where: { courseId } });
  if (!enrolments.length) return;

  // Get current matrix version if not provided
  if (!matrixVersion) {
    const latest = await prisma.coPoMapping.findFirst({
      where: { courseId }, orderBy: { version: 'desc' },
    });
    matrixVersion = latest?.version || 1;
  }

  const cos = await prisma.courseOutcome.findMany({ where: { courseId, deletedAt: null } });
  const assessments = await prisma.assessment.findMany({
    where: { courseId, deletedAt: null },
    include: { assessmentCOs: true, marks: true },
  });
  const mappings = await prisma.coPoMapping.findMany({ where: { courseId } });

  // Collect all unique PO ids referenced by this course's mappings
  const poIds = [...new Set(mappings.map(m => m.programOutcomeId))];

  const coUpdates = [];
  const poUpdates = [];

  for (const enrolment of enrolments) {
    const studentId = enrolment.studentId;

    // ── CO attainment (binary) ─────────────────────────────────
    // ratio = Σ(marks×weight) / Σ(totalMarks×weight) >= 60%
    const coAttainmentMap = {};
    for (const co of cos) {
      const result = computeCOAttainment(studentId, co, assessments);
      if (!result) continue;
      coAttainmentMap[co.id] = result;

      coUpdates.push(
        prisma.coAttainment.upsert({
          where: { courseOutcomeId_studentId: { courseOutcomeId: co.id, studentId } },
          create: {
            courseOutcomeId: co.id, studentId, courseId,
            percentage: result.percentage,
            level: result.level,
            matrixVersion,
          },
          update: {
            percentage: result.percentage,
            level: result.level,
            matrixVersion,
            computedAt: new Date(),
          },
        })
      );
    }

    // ── PO attainment (binary) ─────────────────────────────────
    // ratio = Σ(corr × coAttained) / Σ(corr) >= 60%
    for (const poId of poIds) {
      const result = computePOAttainment(coAttainmentMap, mappings, poId);
      if (!result) continue;

      poUpdates.push(
        prisma.poAttainment.upsert({
          where: { programOutcomeId_studentId_courseId: { programOutcomeId: poId, studentId, courseId } },
          create: {
            programOutcomeId: poId, studentId, courseId,
            percentage: result.percentage,
            level: result.level,
            matrixVersion,
          },
          update: {
            percentage: result.percentage,
            level: result.level,
            matrixVersion,
            computedAt: new Date(),
          },
        })
      );
    }
  }

  // Batch to avoid transaction size limits
  const BATCH = 50;
  for (let i = 0; i < coUpdates.length; i += BATCH)
    await prisma.$transaction(coUpdates.slice(i, i + BATCH));
  for (let i = 0; i < poUpdates.length; i += BATCH)
    await prisma.$transaction(poUpdates.slice(i, i + BATCH));
}

module.exports = {
  getMyCourses,
  getCourseOutcomes, createCourseOutcome, updateCourseOutcome, deleteCourseOutcome,
  getMapping, saveMapping,
  getAssessments, createAssessment, updateAssessment, deleteAssessment,
  getMarks, saveMarks,
  getCourseAttainment,
  recomputeAttainmentForCourse,
};
