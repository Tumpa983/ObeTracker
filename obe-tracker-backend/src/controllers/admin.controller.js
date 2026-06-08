const bcrypt = require('bcrypt');
const prisma = require('../prisma');

// ── Departments ──────────────────────────────────────────────
const getDepartments = async (req, res, next) => {
  try {
    const items = await prisma.department.findMany({
      where: { institutionId: req.user.institutionId, deletedAt: null },
      include: { _count: { select: { programs: true } } },
    });
    res.json({ status: 'success', data: items });
  } catch (err) { next(err); }
};

const createDepartment = async (req, res, next) => {
  try {
    const { name, code } = req.body;
    const item = await prisma.department.create({
      data: { name, code: code.toUpperCase(), institutionId: req.user.institutionId },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateDepartment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, code } = req.body;
    const item = await prisma.department.update({ where: { id }, data: { name, code: code?.toUpperCase() } });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteDepartment = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.department.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'Department deactivated' } });
  } catch (err) { next(err); }
};

// ── Programs ─────────────────────────────────────────────────
const getPrograms = async (req, res, next) => {
  try {
    const items = await prisma.program.findMany({
      where: { department: { institutionId: req.user.institutionId }, deletedAt: null },
      include: { department: { select: { name: true, code: true } }, _count: { select: { courses: true } } },
    });
    res.json({ status: 'success', data: items });
  } catch (err) { next(err); }
};

const createProgram = async (req, res, next) => {
  try {
    const { departmentId, name, code } = req.body;
    const item = await prisma.program.create({ data: { departmentId, name, code: code.toUpperCase() } });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateProgram = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, code } = req.body;
    const item = await prisma.program.update({ where: { id }, data: { name, code: code?.toUpperCase() } });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteProgram = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.program.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'Program deactivated' } });
  } catch (err) { next(err); }
};

// ── Sessions ─────────────────────────────────────────────────
const getSessions = async (req, res, next) => {
  try {
    const items = await prisma.session.findMany({
      where: { institutionId: req.user.institutionId },
      orderBy: { startDate: 'desc' },
    });
    res.json({ status: 'success', data: items });
  } catch (err) { next(err); }
};

const createSession = async (req, res, next) => {
  try {
    const { name, startDate, endDate } = req.body;
    const item = await prisma.session.create({
      data: { name, startDate: new Date(startDate), endDate: endDate ? new Date(endDate) : null, institutionId: req.user.institutionId },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateSession = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, startDate, endDate, status } = req.body;
    const session = await prisma.session.findUnique({ where: { id } });

    let frozenThresholds = session.frozenThresholds;
    // Freeze thresholds on close
    if (status === 'CLOSED' && session.status !== 'CLOSED') {
      const th = await prisma.attainmentThreshold.findUnique({ where: { institutionId: req.user.institutionId } });
      frozenThresholds = th ? { l3Min: th.l3Min, l2Min: th.l2Min, l1Min: th.l1Min } : null;
    }

    const item = await prisma.session.update({
      where: { id },
      data: {
        name, status,
        startDate: startDate ? new Date(startDate) : undefined,
        endDate: endDate ? new Date(endDate) : undefined,
        frozenThresholds,
      },
    });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

// ── Courses ──────────────────────────────────────────────────
const getCourses = async (req, res, next) => {
  try {
    const { sessionId, programId } = req.query;
    const items = await prisma.course.findMany({
      where: {
        deletedAt: null,
        ...(sessionId && { sessionId }),
        ...(programId && { programId }),
        program: { department: { institutionId: req.user.institutionId } },
      },
      include: {
        program: { select: { name: true, code: true } },
        session: { select: { name: true } },
        assignments: { include: { faculty: { select: { id: true, firstName: true, lastName: true, email: true } } } },
      },
    });
    res.json({ status: 'success', data: items });
  } catch (err) { next(err); }
};

const createCourse = async (req, res, next) => {
  try {
    const { programId, sessionId, name, code, creditHours } = req.body;
    const item = await prisma.course.create({
      data: { programId, sessionId, name, code: code.toUpperCase(), creditHours: creditHours || 3 },
    });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateCourse = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, code, creditHours } = req.body;
    const item = await prisma.course.update({ where: { id }, data: { name, code: code?.toUpperCase(), creditHours } });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteCourse = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.course.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'Course deactivated' } });
  } catch (err) { next(err); }
};

const assignFaculty = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { facultyIds } = req.body; // array of user IDs
    // Replace all assignments
    await prisma.courseAssignment.deleteMany({ where: { courseId: id } });
    if (facultyIds?.length) {
      await prisma.courseAssignment.createMany({
        data: facultyIds.map(facultyId => ({ courseId: id, facultyId })),
        skipDuplicates: true,
      });
    }
    res.json({ status: 'success', data: { message: 'Faculty assigned' } });
  } catch (err) { next(err); }
};

// ── User Management ──────────────────────────────────────────
const getUsers = async (req, res, next) => {
  try {
    const { role, isActive, search } = req.query;
    const users = await prisma.user.findMany({
      where: {
        institutionId: req.user.institutionId,
        deletedAt: null,
        ...(role && { role }),
        ...(isActive !== undefined && { isActive: isActive === 'true' }),
        ...(search && {
          OR: [
            { email: { contains: search, mode: 'insensitive' } },
            { firstName: { contains: search, mode: 'insensitive' } },
            { lastName: { contains: search, mode: 'insensitive' } },
          ],
        }),
      },
      select: {
        id: true, email: true, role: true, firstName: true, lastName: true,
        institutionalId: true, isActive: true, lastLoginAt: true, createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ status: 'success', data: users });
  } catch (err) { next(err); }
};

const createUser = async (req, res, next) => {
  try {
    const { email, role, firstName, lastName, institutionalId, password } = req.body;
    if (!email || !role || !firstName || !lastName) {
      return res.status(400).json({ status: 'error', error: 'email, role, firstName and lastName are required' });
    }
    // Check for duplicate email before attempting insert
    const existing = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
    if (existing) {
      return res.status(409).json({ status: 'error', error: `A user with email ${email} already exists` });
    }
    const tempPassword = password || Math.random().toString(36).slice(-10) + 'A1';
    const passwordHash = await bcrypt.hash(tempPassword, Number(process.env.BCRYPT_COST) || 10);
    const user = await prisma.user.create({
      data: {
        email: email.toLowerCase(), role, firstName, lastName,
        institutionalId: institutionalId || null,
        passwordHash, institutionId: req.user.institutionId,
      },
      select: { id: true, email: true, role: true, firstName: true, lastName: true },
    });
    res.status(201).json({ status: 'success', data: { user, tempPassword } });
  } catch (err) { next(err); }
};

const updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { firstName, lastName, institutionalId, isActive } = req.body;
    const user = await prisma.user.update({
      where: { id },
      data: { firstName, lastName, institutionalId, isActive },
      select: { id: true, email: true, role: true, firstName: true, lastName: true, isActive: true },
    });
    res.json({ status: 'success', data: user });
  } catch (err) { next(err); }
};

// ── Thresholds ───────────────────────────────────────────────
const getThresholds = async (req, res, next) => {
  try {
    const th = await prisma.attainmentThreshold.findUnique({ where: { institutionId: req.user.institutionId } });
    res.json({ status: 'success', data: { attainmentThreshold: 60, note: 'Binary model: CO/PO attained if ≥ 60% of weighted marks' } });
  } catch (err) { next(err); }
};

const upsertThresholds = async (req, res, next) => {
  try {
    // Binary model: threshold is fixed at 60%. This endpoint is kept for compatibility.
    res.json({ status: 'success', data: { attainmentThreshold: 60 } });
  } catch (err) { next(err); }
};

// ── Program Outcomes (Admin defines POs) ─────────────────────
const getProgramOutcomes = async (req, res, next) => {
  try {
    const { programId } = req.params;
    const items = await prisma.programOutcome.findMany({
      where: { programId, deletedAt: null },
    });
    // Sort numerically: PO1, PO2, ..., PO10, PO11, PO12
    items.sort((a, b) => {
      const numA = parseInt(a.code.replace(/\D+/g, ''), 10);
      const numB = parseInt(b.code.replace(/\D+/g, ''), 10);
      if (!isNaN(numA) && !isNaN(numB)) return numA - numB;
      return a.code.localeCompare(b.code);
    });
    res.json({ status: 'success', data: items });
  } catch (err) { next(err); }
};

const createProgramOutcome = async (req, res, next) => {
  try {
    const { programId } = req.params;
    const { code, title, description } = req.body;
    const item = await prisma.programOutcome.create({ data: { programId, code, title, description } });
    res.status(201).json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const updateProgramOutcome = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { code, title, description } = req.body;
    const item = await prisma.programOutcome.update({ where: { id }, data: { code, title, description } });
    res.json({ status: 'success', data: item });
  } catch (err) { next(err); }
};

const deleteProgramOutcome = async (req, res, next) => {
  try {
    const { id } = req.params;
    const hasMapping = await prisma.coPoMapping.findFirst({ where: { programOutcomeId: id } });
    if (hasMapping) return res.status(409).json({ status: 'error', error: 'PO is referenced by a mapping. Remove mappings first.' });
    await prisma.programOutcome.update({ where: { id }, data: { deletedAt: new Date(), isActive: false } });
    res.json({ status: 'success', data: { message: 'PO deactivated' } });
  } catch (err) { next(err); }
};

// ── Institution-wide Dashboard ────────────────────────────────
const getDashboard = async (req, res, next) => {
  try {
    const institutionId = req.user.institutionId;
    const [deptCount, programCount, courseCount, userCount] = await Promise.all([
      prisma.department.count({ where: { institutionId, deletedAt: null } }),
      prisma.program.count({ where: { department: { institutionId }, deletedAt: null } }),
      prisma.course.count({ where: { program: { department: { institutionId } }, deletedAt: null } }),
      prisma.user.count({ where: { institutionId, isActive: true, deletedAt: null } }),
    ]);
    res.json({ status: 'success', data: { deptCount, programCount, courseCount, userCount } });
  } catch (err) { next(err); }
};

module.exports = {
  getDepartments, createDepartment, updateDepartment, deleteDepartment,
  getPrograms, createProgram, updateProgram, deleteProgram,
  getSessions, createSession, updateSession,
  getCourses, createCourse, updateCourse, deleteCourse, assignFaculty,
  getUsers, createUser, updateUser,
  getThresholds, upsertThresholds,
  getProgramOutcomes, createProgramOutcome, updateProgramOutcome, deleteProgramOutcome,
  getDashboard,
};
