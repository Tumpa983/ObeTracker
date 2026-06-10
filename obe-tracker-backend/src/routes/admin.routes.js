const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const c = require('../controllers/admin.controller');

router.use(authenticate, authorize('ADMIN'));

// Dashboard
router.get('/dashboard', c.getDashboard);

// Departments
router.get('/departments', c.getDepartments);
router.post('/departments', c.createDepartment);
router.put('/departments/:id', c.updateDepartment);
router.delete('/departments/:id', c.deleteDepartment);

// Programs
router.get('/programs', c.getPrograms);
router.post('/programs', c.createProgram);
router.put('/programs/:id', c.updateProgram);
router.delete('/programs/:id', c.deleteProgram);

// Program Outcomes
router.get('/programs/:programId/outcomes', c.getProgramOutcomes);
router.post('/programs/:programId/outcomes', c.createProgramOutcome);
router.put('/outcomes/:id', c.updateProgramOutcome);
router.delete('/outcomes/:id', c.deleteProgramOutcome);

// Sessions
router.get('/sessions', c.getSessions);
router.post('/sessions', c.createSession);
router.put('/sessions/:id', c.updateSession);

// Courses
router.get('/courses', c.getCourses);
router.post('/courses', c.createCourse);
router.put('/courses/:id', c.updateCourse);
router.delete('/courses/:id', c.deleteCourse);
router.put('/courses/:id/faculty', c.assignFaculty);

// Users
router.get('/users', c.getUsers);
router.post('/users', c.createUser);
router.put('/users/:id', c.updateUser);

// Thresholds
router.get('/thresholds', c.getThresholds);
router.get('/attainment-report', c.getAttainmentReport);
router.put('/thresholds', c.upsertThresholds);

module.exports = router;
