const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // ── Institution ───────────────────────────────────────────────
  const institution = await prisma.institution.upsert({
    where: { code: 'BUP' },
    update: {},
    create: { name: 'Bangladesh University of Professionals', code: 'BUP' },
  });

  await prisma.attainmentThreshold.upsert({
    where: { institutionId: institution.id },
    update: {},
    create: { institutionId: institution.id, l3Min: 70, l2Min: 60, l1Min: 50 },
  });
  console.log('✓ Institution & thresholds');

  // ── Admin (login: admin / 1234) ───────────────────────────────
  const adminHash = await bcrypt.hash('1234', 10);
  await prisma.user.upsert({
    where: { email: 'admin@bup.edu.bd' },
    update: { passwordHash: adminHash },
    create: {
      email: 'admin@bup.edu.bd', passwordHash: adminHash,
      role: 'ADMIN', firstName: 'System', lastName: 'Admin',
      institutionId: institution.id,
    },
  });
  console.log('✓ Admin  (email: admin@bup.edu.bd  password: 1234)');

  // ── Faculty (login: AZ / 1234  and  RAI / 1234) ───────────────
  const facHash = await bcrypt.hash('1234', 10);

  const abrar = await prisma.user.upsert({
    where: { email: 'AZ@bup.edu.bd' },
    update: { passwordHash: facHash },
    create: {
      email: 'AZ@bup.edu.bd', passwordHash: facHash,
      role: 'FACULTY', firstName: 'Abrar', lastName: 'Zawad',
      institutionId: institution.id,
    },
  });

  const refath = await prisma.user.upsert({
    where: { email: 'RAI@bup.edu.bd' },
    update: { passwordHash: facHash },
    create: {
      email: 'RAI@bup.edu.bd', passwordHash: facHash,
      role: 'FACULTY', firstName: 'Refath Ara', lastName: 'Islam',
      institutionId: institution.id,
    },
  });
  console.log('✓ Faculty: AZ@bup.edu.bd / 1234   RAI@bup.edu.bd / 1234');

  // ── Department & Program ──────────────────────────────────────
  const deptICE = await prisma.department.upsert({
    where: { institutionId_code: { institutionId: institution.id, code: 'ICE' } },
    update: {},
    create: {
      institutionId: institution.id,
      name: 'Department of Information and Communication Engineering',
      code: 'ICE',
    },
  });

  const progBICE = await prisma.program.upsert({
    where: { departmentId_code: { departmentId: deptICE.id, code: 'BICE' } },
    update: {},
    create: {
      departmentId: deptICE.id,
      name: 'Bachelor of Science in Information and Communication Engineering',
      code: 'BICE',
    },
  });
  console.log('✓ Department ICE · Program BICE');

  // ── Program Outcomes PO1-PO12 ─────────────────────────────────
  const poData = [
    { code: 'PO1',  title: 'Engineering Knowledge',
      description: 'Apply knowledge of mathematics, natural science, engineering fundamentals and an engineering specialisation to defined and applied engineering procedures and problems.' },
    { code: 'PO2',  title: 'Problem Analysis',
      description: 'Identify and analyse well-defined engineering problems reaching substantiated conclusions using codified methods of analysis.' },
    { code: 'PO3',  title: 'Design/Development of Solutions',
      description: 'Design solutions for well-defined technical problems and assist with the design of systems, components or processes to meet specified needs.' },
    { code: 'PO4',  title: 'Investigation',
      description: 'Conduct investigations of well-defined problems, locate and search relevant codes and catalogues, and interpret and apply data.' },
    { code: 'PO5',  title: 'Modern Tool Usage',
      description: 'Select and apply appropriate techniques, resources and modern engineering tools to well-defined engineering activities.' },
    { code: 'PO6',  title: 'The Engineer and Society',
      description: 'Demonstrate awareness of societal, health, safety, legal and cultural issues and the consequent responsibilities relevant to engineering practice.' },
    { code: 'PO7',  title: 'Environment and Sustainability',
      description: 'Understand the impact of engineering activities on the environment and society through application of sustainable development principles.' },
    { code: 'PO8',  title: 'Ethics',
      description: 'Understand and commit to professional ethics, responsibilities and norms of engineering practice.' },
    { code: 'PO9',  title: 'Individual and Teamwork',
      description: 'Function effectively as an individual and as a member in technical teams.' },
    { code: 'PO10', title: 'Communication',
      description: 'Communicate effectively on well-defined engineering activities with the engineering community and with society at large.' },
    { code: 'PO11', title: 'Project Management and Finance',
      description: 'Demonstrate knowledge and understanding of engineering management principles and apply in teams.' },
    { code: 'PO12', title: 'Lifelong Learning',
      description: 'Recognise the need for, and have the ability to engage in independent and life-long learning in a defined context.' },
  ];

  const poMap = {};
  for (const po of poData) {
    const r = await prisma.programOutcome.upsert({
      where: { programId_code: { programId: progBICE.id, code: po.code } },
      update: {},
      create: { programId: progBICE.id, ...po },
    });
    poMap[po.code] = r.id;
  }
  console.log('✓ PO1-PO12');

  // ── Sessions ──────────────────────────────────────────────────
  const batchData = [
    { id: 'session-batch-2022', name: 'Batch 2022', start: '2022-01-01', end: '2026-06-30' },
    { id: 'session-batch-2023', name: 'Batch 2023', start: '2023-01-01', end: '2027-06-30' },
    { id: 'session-batch-2024', name: 'Batch 2024', start: '2024-01-01', end: '2028-06-30' },
    { id: 'session-batch-2025', name: 'Batch 2025', start: '2025-01-01', end: '2029-06-30' },
    { id: 'session-batch-2026', name: 'Batch 2026', start: '2026-01-01', end: '2030-06-30' },
  ];
  const sessions = {};
  for (const b of batchData) {
    sessions[b.name] = await prisma.session.upsert({
      where: { id: b.id },
      update: {},
      create: { id: b.id, institutionId: institution.id, name: b.name, startDate: new Date(b.start), endDate: new Date(b.end), status: 'ACTIVE' },
    });
  }
  console.log('✓ Sessions Batch 2022-2026');

  // ── Courses ───────────────────────────────────────────────────
  const sre = await prisma.course.upsert({
    where: { sessionId_code: { sessionId: sessions['Batch 2023'].id, code: 'ICE-3207' } },
    update: {},
    create: { programId: progBICE.id, sessionId: sessions['Batch 2023'].id, name: 'Software and Requirement Engineering', code: 'ICE-3207', creditHours: 3 },
  });

  const web = await prisma.course.upsert({
    where: { sessionId_code: { sessionId: sessions['Batch 2023'].id, code: 'ICE-3205' } },
    update: {},
    create: { programId: progBICE.id, sessionId: sessions['Batch 2023'].id, name: 'Web Technologies', code: 'ICE-3205', creditHours: 3 },
  });

  const ai = await prisma.course.upsert({
    where: { sessionId_code: { sessionId: sessions['Batch 2022'].id, code: 'ICE-4107' } },
    update: {},
    create: { programId: progBICE.id, sessionId: sessions['Batch 2022'].id, name: 'Artificial Intelligence', code: 'ICE-4107', creditHours: 3 },
  });

  // SRE (ICE-3207) → Abrar Zawad (primary grader)
  await prisma.courseAssignment.upsert({
    where: { courseId_facultyId: { courseId: sre.id, facultyId: abrar.id } },
    update: {},
    create: { courseId: sre.id, facultyId: abrar.id },
  });
  // Web Technologies (ICE-3205) → Refath Ara Islam (primary grader)
  await prisma.courseAssignment.upsert({
    where: { courseId_facultyId: { courseId: web.id, facultyId: refath.id } },
    update: {},
    create: { courseId: web.id, facultyId: refath.id },
  });
  // Artificial Intelligence (ICE-4107) → both faculty
  for (const fac of [abrar, refath]) {
    await prisma.courseAssignment.upsert({
      where: { courseId_facultyId: { courseId: ai.id, facultyId: fac.id } },
      update: {},
      create: { courseId: ai.id, facultyId: fac.id },
    });
  }
  console.log('✓ Course assignments:');
  console.log('  ICE-3207 SRE             → Abrar Zawad (sole grader)');
  console.log('  ICE-3205 Web Technologies → Refath Ara Islam (sole grader)');
  console.log('  ICE-4107 AI              → both faculty');

  // ── Course Outcomes ───────────────────────────────────────────
  // Helper: profiles stored as JSON in profileCode field
  const profiles = (arr) => JSON.stringify(arr);

  // ── ICE-3207 Software and Requirement Engineering ─────────────
  // CO1: Understand software process models and requirement elicitation → PO1 (Knowledge) + PO2 (Problem Analysis)
  const sre_co1 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: sre.id, code: 'CO1' } },
    update: {},
    create: {
      courseId: sre.id, code: 'CO1',
      title: 'Software Process & Requirement Elicitation',
      description: 'Understand and apply software process models and elicit requirements from stakeholders using structured techniques.',
      bloomDomain: 'COGNITIVE', bloomLevel: 3,
      profileType: 'FUNDAMENTAL',
      profileCode: profiles([{ type: 'FUNDAMENTAL', code: 'F1' }, { type: 'THINKING', code: 'T1' }]),
    },
  });

  // CO2: Analyse and specify software requirements using formal notations → PO2 (Problem Analysis) + PO3 (Design)
  const sre_co2 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: sre.id, code: 'CO2' } },
    update: {},
    create: {
      courseId: sre.id, code: 'CO2',
      title: 'Requirements Analysis & Specification',
      description: 'Analyse, model and formally specify software requirements using use-case diagrams, user stories and SRS documents.',
      bloomDomain: 'COGNITIVE', bloomLevel: 4,
      profileType: 'THINKING',
      profileCode: profiles([{ type: 'THINKING', code: 'T2' }, { type: 'FUNDAMENTAL', code: 'F2' }]),
    },
  });

  // CO3: Evaluate and validate requirements for correctness and completeness → PO4 (Investigation) + PO9 (Teamwork)
  const sre_co3 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: sre.id, code: 'CO3' } },
    update: {},
    create: {
      courseId: sre.id, code: 'CO3',
      title: 'Requirements Validation & Management',
      description: 'Evaluate, validate and manage software requirements through reviews, prototyping and change control processes.',
      bloomDomain: 'COGNITIVE', bloomLevel: 5,
      profileType: 'SOCIAL',
      profileCode: profiles([{ type: 'SOCIAL', code: 'S1' }, { type: 'PERSONAL', code: 'P1' }]),
    },
  });
  console.log('✓ COs for ICE-3207 (SRE)');

  // ── ICE-3205 Web Technologies ─────────────────────────────────
  // CO1: Apply HTML/CSS/JS to build structured, styled web interfaces → PO1 + PO5 (Tools)
  const web_co1 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: web.id, code: 'CO1' } },
    update: {},
    create: {
      courseId: web.id, code: 'CO1',
      title: 'Front-End Web Development',
      description: 'Apply HTML5, CSS3 and JavaScript to design and implement accessible, responsive web interfaces.',
      bloomDomain: 'COGNITIVE', bloomLevel: 3,
      profileType: 'FUNDAMENTAL',
      profileCode: profiles([{ type: 'FUNDAMENTAL', code: 'F1' }, { type: 'THINKING', code: 'T1' }]),
    },
  });

  // CO2: Develop dynamic web applications using server-side technologies → PO3 (Design) + PO5 (Tools)
  const web_co2 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: web.id, code: 'CO2' } },
    update: {},
    create: {
      courseId: web.id, code: 'CO2',
      title: 'Server-Side & Database Integration',
      description: 'Develop dynamic web applications integrating server-side scripting, RESTful APIs and relational databases.',
      bloomDomain: 'COGNITIVE', bloomLevel: 4,
      profileType: 'FUNDAMENTAL',
      profileCode: profiles([{ type: 'FUNDAMENTAL', code: 'F2' }, { type: 'THINKING', code: 'T2' }]),
    },
  });

  // CO3: Evaluate web security practices and deploy applications → PO6 (Society) + PO8 (Ethics)
  const web_co3 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: web.id, code: 'CO3' } },
    update: {},
    create: {
      courseId: web.id, code: 'CO3',
      title: 'Web Security & Deployment',
      description: 'Evaluate common web security vulnerabilities and apply best practices to deploy secure, maintainable web applications.',
      bloomDomain: 'COGNITIVE', bloomLevel: 5,
      profileType: 'SOCIAL',
      profileCode: profiles([{ type: 'SOCIAL', code: 'S1' }, { type: 'PERSONAL', code: 'P1' }]),
    },
  });
  console.log('✓ COs for ICE-3205 (Web Technologies)');

  // ── ICE-4107 Artificial Intelligence ──────────────────────────
  // CO1: Explain AI concepts, search strategies and knowledge representation → PO1 + PO12 (Lifelong)
  const ai_co1 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: ai.id, code: 'CO1' } },
    update: {},
    create: {
      courseId: ai.id, code: 'CO1',
      title: 'AI Fundamentals & Knowledge Representation',
      description: 'Explain core AI concepts, search strategies and knowledge representation schemes including logic and semantic networks.',
      bloomDomain: 'COGNITIVE', bloomLevel: 2,
      profileType: 'FUNDAMENTAL',
      profileCode: profiles([{ type: 'FUNDAMENTAL', code: 'F1' }]),
    },
  });

  // CO2: Design and implement machine learning models for real-world problems → PO2 + PO3 + PO5
  const ai_co2 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: ai.id, code: 'CO2' } },
    update: {},
    create: {
      courseId: ai.id, code: 'CO2',
      title: 'Machine Learning Model Design',
      description: 'Design, implement and evaluate supervised and unsupervised machine learning models to solve well-defined engineering problems.',
      bloomDomain: 'COGNITIVE', bloomLevel: 4,
      profileType: 'THINKING',
      profileCode: profiles([{ type: 'THINKING', code: 'T1' }, { type: 'FUNDAMENTAL', code: 'F2' }]),
    },
  });

  // CO3: Assess ethical implications and societal impact of AI systems → PO6 + PO8
  const ai_co3 = await prisma.courseOutcome.upsert({
    where: { courseId_code: { courseId: ai.id, code: 'CO3' } },
    update: {},
    create: {
      courseId: ai.id, code: 'CO3',
      title: 'AI Ethics & Societal Impact',
      description: 'Assess ethical considerations, bias, fairness and the societal impact of AI systems in engineering contexts.',
      bloomDomain: 'AFFECTIVE', bloomLevel: 4,
      profileType: 'SOCIAL',
      profileCode: profiles([{ type: 'SOCIAL', code: 'S1' }, { type: 'PERSONAL', code: 'P1' }]),
    },
  });
  console.log('✓ COs for ICE-4107 (Artificial Intelligence)');

  // ── CO-PO Mappings ────────────────────────────────────────────
  // Correlation levels: WEAK=1, MODERATE=2, STRONG=3
  const mapData = [
    // ICE-3207 SRE
    // CO1: Software Process & Requirement Elicitation → PO1 Strong, PO2 Moderate, PO12 Weak
    { coId: sre_co1.id, poCode: 'PO1',  correlation: 'STRONG'   },
    { coId: sre_co1.id, poCode: 'PO2',  correlation: 'MODERATE' },
    { coId: sre_co1.id, poCode: 'PO12', correlation: 'WEAK'     },
    // CO2: Requirements Analysis → PO2 Strong, PO3 Strong, PO4 Moderate
    { coId: sre_co2.id, poCode: 'PO2',  correlation: 'STRONG'   },
    { coId: sre_co2.id, poCode: 'PO3',  correlation: 'STRONG'   },
    { coId: sre_co2.id, poCode: 'PO4',  correlation: 'MODERATE' },
    // CO3: Requirements Validation → PO4 Strong, PO9 Strong, PO10 Moderate
    { coId: sre_co3.id, poCode: 'PO4',  correlation: 'STRONG'   },
    { coId: sre_co3.id, poCode: 'PO9',  correlation: 'STRONG'   },
    { coId: sre_co3.id, poCode: 'PO10', correlation: 'MODERATE' },

    // ICE-3205 Web Technologies
    // CO1: Front-End → PO1 Strong, PO5 Strong, PO3 Moderate
    { coId: web_co1.id, poCode: 'PO1',  correlation: 'STRONG'   },
    { coId: web_co1.id, poCode: 'PO5',  correlation: 'STRONG'   },
    { coId: web_co1.id, poCode: 'PO3',  correlation: 'MODERATE' },
    // CO2: Server-Side → PO3 Strong, PO5 Strong, PO2 Moderate
    { coId: web_co2.id, poCode: 'PO3',  correlation: 'STRONG'   },
    { coId: web_co2.id, poCode: 'PO5',  correlation: 'STRONG'   },
    { coId: web_co2.id, poCode: 'PO2',  correlation: 'MODERATE' },
    // CO3: Security & Deployment → PO6 Strong, PO8 Strong, PO7 Moderate
    { coId: web_co3.id, poCode: 'PO6',  correlation: 'STRONG'   },
    { coId: web_co3.id, poCode: 'PO8',  correlation: 'STRONG'   },
    { coId: web_co3.id, poCode: 'PO7',  correlation: 'MODERATE' },

    // ICE-4107 Artificial Intelligence
    // CO1: Fundamentals → PO1 Strong, PO12 Moderate
    { coId: ai_co1.id, poCode: 'PO1',  correlation: 'STRONG'   },
    { coId: ai_co1.id, poCode: 'PO12', correlation: 'MODERATE' },
    // CO2: ML Design → PO2 Strong, PO3 Strong, PO5 Strong, PO4 Moderate
    { coId: ai_co2.id, poCode: 'PO2',  correlation: 'STRONG'   },
    { coId: ai_co2.id, poCode: 'PO3',  correlation: 'STRONG'   },
    { coId: ai_co2.id, poCode: 'PO5',  correlation: 'STRONG'   },
    { coId: ai_co2.id, poCode: 'PO4',  correlation: 'MODERATE' },
    // CO3: Ethics & Impact → PO6 Strong, PO8 Strong, PO9 Moderate
    { coId: ai_co3.id, poCode: 'PO6',  correlation: 'STRONG'   },
    { coId: ai_co3.id, poCode: 'PO8',  correlation: 'STRONG'   },
    { coId: ai_co3.id, poCode: 'PO9',  correlation: 'MODERATE' },
  ];

  // Attach courseId to each mapping entry
  const coToCourse = {};
  for (const co of [sre_co1, sre_co2, sre_co3]) coToCourse[co.id] = sre.id;
  for (const co of [web_co1, web_co2, web_co3]) coToCourse[co.id] = web.id;
  for (const co of [ai_co1, ai_co2, ai_co3])   coToCourse[co.id] = ai.id;

  for (const m of mapData) {
    const courseId = coToCourse[m.coId];
    const programOutcomeId = poMap[m.poCode];
    await prisma.coPoMapping.upsert({
      where: {
        courseId_courseOutcomeId_programOutcomeId: {
          courseId,
          courseOutcomeId: m.coId,
          programOutcomeId,
        },
      },
      update: { correlation: m.correlation, version: 1 },
      create: {
        courseId,
        courseOutcomeId: m.coId,
        programOutcomeId,
        correlation: m.correlation,
        version: 1,
      },
    });
  }
  console.log('✓ CO-PO mappings (9 per course, 27 total)');

  // ── Students (login: studentId / 1234) ────────────────────────
  const studentList = [
    ['23549009001','SUBAHA NURAIN','POURBI'],
    ['23549009002','ABEEDA UMMEY','HAAFSA'],
    ['23549009003','RAKIBUL','HASAN'],
    ['23549009004','REEFAH TASNIA','ROZONI'],
    ['23549009005','MD. HEMEL','PARVEJ'],
    ['23549009006','SUPRIO CHATTAPADHYA','RAJ'],
    ['23549009007','S M NAZIB UL','ALAM'],
    ['23549009008','AFIA','TASNIA'],
    ['23549009011','MD. SALMAN','ZAHID'],
    ['23549009012','HUMAIRA BINTE','MIZAN'],
    ['23549009013','MD. RAZOWAN','RABBI'],
    ['23549009020','AFIFA','HUMAYRA'],
    ['23549009021','RATRIXMNA','CHAKMA'],
    ['23549009022','S. M ABRAR ZAWAD','YOBORAJ'],
    ['23549009023','MAHANAZ','AFRIN'],
    ['23549009025','SAIDA','JAHAN'],
    ['23549009026','MD ISA BIN HABIB KHAN','NIROZ'],
    ['23549009027','ANIKA FAIRUZ','KHAN'],
    ['23549009029','SHAFIKA BINTE','ISMAIL'],
    ['23549009030','MD. ASIF AHMED','REZVI'],
    ['23549009031','FARZANA HOSSAIN','MIMI'],
    ['23549009032','ABRAR LABIB','TARAFDER'],
    ['23549009033','SUMIYA','AFRIN'],
    ['23549009034','AL','MOHIAN'],
    ['23549009037','SADMAN','SAKIB'],
    ['23549009038','MD. SAFIL','SARKER'],
    ['23549009039','MD. EFTHA KHARUL HAQUE','EFATH'],
    ['23549009040','ATIQUL ISLAM','SAYEM'],
    ['23549009041','LAIBA SUMAIYA','NAZIM'],
    ['23549009042','MUNTASIR','AHAMMED'],
    ['23549009043','ROWNOK TANVIN','AVA'],
    ['23549009044','BEENA RANI','DAS'],
    ['23549009045','SABIQUN NAHER','SAMIA'],
    ['23549009048','MD. MEHEDI HASSAN','RIDOY'],
    ['23549009052','MD. SAJIDUL','ISLAM'],
    ['23549009053','MD. NAZMUS SAKIB','SIAM'],
    ['23549009054','REFATH ARA','ISLAM'],
    ['23549009055','KHONDAKAR ANIQA','TASNEEM'],
    ['23549009056','FUAD AL','HASAN'],
    ['23549009061','MD. FARDOUS HOSSIN KHAN','NAHID'],
    ['23549009063','TASMIM ANAN','PROTIVA'],
    ['23549009065','MD SHAHRIAR NASIM','SHAWON'],
    ['23549009067','MD. SADMAN','SAKIB'],
    ['23549009069','MD. MEJBAUL ISLAM','ZIDAN'],
    ['23549009070','SAMIA RAHMAN','SHAMMI'],
    ['23549009071','SUMAYA','SANZIDA'],
    ['23549009073','TOWHIDUR RAHMAN','TALUKDAR'],
    ['23549009074','MAISHA MONWAR','PRODIPTA'],
    ['23549009075','MD. RIDWAN','RAHMAN'],
    ['23549009076','ISHTIAK HAQUE','SADMAN'],
    ['23549009078','TAHIA','PARSHA'],
    ['23549009081','JAKI - UL - ALAM','KHAN'],
    ['23549009085','MD. TANVIR','HOSSEN'],
    ['23549009087','SAMIHAH SULTANA','ERA'],
    ['23549009090','FAHIM','AHMED'],
    ['23549009091','MUSAYEB HOSSAIN','USAMA'],
    ['23549009093','MASUMA TASNIM','NIMO'],
    ['23549009095','MD. MAHFUZUR','RAHMAN'],
    ['23549009096','TASMIN HASAN','FUWAD'],
    ['23549009097','MUHAMMAD ZEEHAD','HASAN'],
    ['23549009098','MAHFUZA KHANUM','MAHE'],
    ['23549009099','RIDA ZAIMAH','KAMAL'],
    ['23549009100','MD. RASHEDUL','ISLAM'],
    ['23549009101','MD. FARIDUR','RAHMAN'],
    ['23549009102','MD. RAFAT HOSSAN','LEON'],
  ];

  const stuHash = await bcrypt.hash('1234', 10);
  const students = [];

  for (const [id, firstName, lastName] of studentList) {
    // email = studentId@bup.edu.bd, password = studentId
    const stuPwHash = await bcrypt.hash(id, 10);
    const stu = await prisma.user.upsert({
      where: { email: `${id}@bup.edu.bd` },
      update: { passwordHash: stuPwHash, institutionalId: id },
      create: {
        email: `${id}@bup.edu.bd`,
        passwordHash: stuPwHash,
        role: 'STUDENT',
        firstName, lastName,
        institutionalId: id,
        institutionId: institution.id,
      },
    });
    students.push(stu);
  }
  console.log(`✓ ${students.length} students created (email: <id>@bup.edu.bd  password: <id>)`);

  // ── Enrol Batch 2023 students in ICE-3207 AND ICE-3205 ──────
  for (const stu of students) {
    await prisma.enrolment.upsert({
      where: { studentId_courseId: { studentId: stu.id, courseId: sre.id } },
      update: {},
      create: { studentId: stu.id, courseId: sre.id, programId: progBICE.id },
    });
    await prisma.enrolment.upsert({
      where: { studentId_courseId: { studentId: stu.id, courseId: web.id } },
      update: {},
      create: { studentId: stu.id, courseId: web.id, programId: progBICE.id },
    });
  }
  console.log(`✓ All ${students.length} students enrolled in ICE-3207 (SRE) and ICE-3205 (Web Technologies)`);

  // ── Summary ───────────────────────────────────────────────────
  console.log('');
  console.log('✅ Seed complete!');
  console.log('');
  console.log('  Credentials');
  console.log('  ─────────────────────────────────────────────────────────────────');
  console.log('  Admin   : admin@bup.edu.bd          password: 1234');
  console.log('  Faculty : AZ@bup.edu.bd             password: 1234  (Abrar Zawad)');
  console.log('  Faculty : RAI@bup.edu.bd            password: 1234  (Refath Ara Islam)');
  console.log('  Student : <studentId>@bup.edu.bd    password: <studentId>');
  console.log('            e.g. 23549009001@bup.edu.bd  password: 23549009001');
  console.log('');
  console.log('  Courses');
  console.log('  ─────────────────────────────────────────────────────────────────');
  console.log('  ICE-3207  Software and Requirement Engineering  Batch 2023  ← 64 students enrolled');
  console.log('  ICE-3205  Web Technologies                      Batch 2024');
  console.log('  ICE-4107  Artificial Intelligence               Batch 2022');
  console.log('');
  console.log('  Course Outcomes (3 per course, with Bloom\'s + profiles + CO-PO maps)');
  console.log('  ─────────────────────────────────────────────────────────────────');
  console.log('  ICE-3207  CO1 Software Process (Cog L3) · CO2 Req Analysis (Cog L4) · CO3 Validation (Cog L5)');
  console.log('  ICE-3205  CO1 Front-End Dev (Cog L3)   · CO2 Server-Side (Cog L4)   · CO3 Security (Cog L5)');
  console.log('  ICE-4107  CO1 AI Fundamentals (Cog L2) · CO2 ML Design (Cog L4)     · CO3 AI Ethics (Aff L4)');

  // ── Assessments & Sample Marks (ICE-3207 only - Batch 2023) ──
  // Weightage plan (no FINAL - excluded as requested):
  //   Quiz 1        10%  20 marks  → CO1
  //   Quiz 2        10%  20 marks  → CO2
  //   Assignment 1  15%  50 marks  → CO1, CO2
  //   Assignment 2  15%  50 marks  → CO2, CO3
  //   Mid Term      25%  100 marks → CO1, CO2, CO3
  //   Lab           15%  50 marks  → CO3
  //   Presentation  10%  30 marks  → CO3
  // Total: 100%

  console.log('');
  console.log('  Seeding assessments and marks for ICE-3207...');

  // Fetch the COs we created for SRE (need their IDs)
  const sreCOs = await prisma.courseOutcome.findMany({
    where: { courseId: sre.id, deletedAt: null },
    orderBy: { code: 'asc' },
  });
  const [co1, co2, co3] = sreCOs;

  // ── ICE-3207 SRE: 3 assessments only ──────────────────────────
  // Total marks per CO:
  //   CO1: Quiz 1 (20) + Mid Term (30 of 60) = 50 total  → attainment = floor(50*0.6) = 30
  //   CO2: Quiz 2 (20) + Mid Term (30 of 60) = 50 total  → attainment = floor(50*0.6) = 30
  //   CO3: Assignment (40) + Mid Term (0 of 60) = 40      → attainment = floor(40*0.6) = 24
  // Mid Term maps to all 3 COs; Quiz 1 → CO1; Quiz 2 → CO2; Assignment → CO3

  const sreAssessmentDefs = [
    { title: 'Quiz 1',    type: 'QUIZ',       totalMarks: 20,  cos: [co1] },
    { title: 'Quiz 2',    type: 'QUIZ',       totalMarks: 20,  cos: [co2] },
    { title: 'Assignment',type: 'ASSIGNMENT', totalMarks: 40,  cos: [co3] },
    { title: 'Mid Term',  type: 'MID_TERM',   totalMarks: 60,  cos: [co1, co2, co3] },
  ];

  const sreAssessments = [];
  for (const def of sreAssessmentDefs) {
    const ass = await prisma.assessment.upsert({
      where: { id: 'seed-ass-sre-' + def.title.toLowerCase().replace(/[^a-z0-9]/g, '-') },
      update: { totalMarks: def.totalMarks, title: def.title },
      create: {
        id: 'seed-ass-sre-' + def.title.toLowerCase().replace(/[^a-z0-9]/g, '-'),
        courseId: sre.id, type: def.type, title: def.title,
        totalMarks: def.totalMarks, weight: 0,
      },
    });
    for (const co of def.cos) {
      await prisma.assessmentCO.upsert({
        where: { assessmentId_courseOutcomeId: { assessmentId: ass.id, courseOutcomeId: co.id } },
        update: {},
        create: { assessmentId: ass.id, courseOutcomeId: co.id },
      });
    }
    sreAssessments.push({ ...ass, coIds: def.cos.map(c => c.id) });
  }
  console.log('  ✓ 4 assessments created for ICE-3207 (SRE)');

  // ── ICE-3205 Web Technologies: 3 assessments only ──────────────
  const webCOs = await prisma.courseOutcome.findMany({
    where: { courseId: web.id, deletedAt: null },
    orderBy: { code: 'asc' },
  });
  const [wco1, wco2, wco3] = webCOs;

  const webAssessmentDefs = [
    { title: 'Quiz 1',    type: 'QUIZ',       totalMarks: 20,  cos: [wco1] },
    { title: 'Quiz 2',    type: 'QUIZ',       totalMarks: 20,  cos: [wco2] },
    { title: 'Assignment',type: 'ASSIGNMENT', totalMarks: 40,  cos: [wco3] },
    { title: 'Mid Term',  type: 'MID_TERM',   totalMarks: 60,  cos: [wco1, wco2, wco3] },
  ];

  const webAssessments = [];
  for (const def of webAssessmentDefs) {
    const ass = await prisma.assessment.upsert({
      where: { id: 'seed-ass-web-' + def.title.toLowerCase().replace(/[^a-z0-9]/g, '-') },
      update: { totalMarks: def.totalMarks, title: def.title },
      create: {
        id: 'seed-ass-web-' + def.title.toLowerCase().replace(/[^a-z0-9]/g, '-'),
        courseId: web.id, type: def.type, title: def.title,
        totalMarks: def.totalMarks, weight: 0,
      },
    });
    for (const co of def.cos) {
      await prisma.assessmentCO.upsert({
        where: { assessmentId_courseOutcomeId: { assessmentId: ass.id, courseOutcomeId: co.id } },
        update: {},
        create: { assessmentId: ass.id, courseOutcomeId: co.id },
      });
    }
    webAssessments.push({ ...ass, coIds: def.cos.map(c => c.id) });
  }
  console.log('  ✓ 4 assessments created for ICE-3205 (Web Technologies)');

  // ── Seeded random helper ────────────────────────────────────────
  function seededRandom(seed) {
    let s = seed;
    return function() {
      s = (s * 16807 + 0) % 2147483647;
      return (s - 1) / 2147483646;
    };
  }

  // ── Per-student ability: uniform random across full range (0-100%) ──
  const studentAbility = {};
  students.forEach((stu, i) => {
    const rng = seededRandom(i * 7919 + 1234);
    studentAbility[stu.id] = 0.30 + rng() * 0.65; // 30-95%, no band classification
  });

  // ── Insert SRE marks (integer values) ──────────────────────────
  let sreMarkCount = 0;
  for (const ass of sreAssessments) {
    for (const stu of students) {
      const rng = seededRandom(stu.id.charCodeAt(0) * 31 + ass.id.charCodeAt(0) * 17);
      const base = studentAbility[stu.id];
      const noise = (rng() - 0.5) * 0.14;
      const pct = Math.min(1.0, Math.max(0.10, base + noise));
      // Integer marks only
      const marksObtained = Math.floor(pct * ass.totalMarks);
      await prisma.mark.upsert({
        where: { assessmentId_studentId: { assessmentId: ass.id, studentId: stu.id } },
        update: { marksObtained },
        create: { assessmentId: ass.id, studentId: stu.id, marksObtained },
      });
      sreMarkCount++;
    }
  }
  console.log(`  ✓ ${sreMarkCount} integer marks inserted for ICE-3207`);

  // ── Insert Web marks (integer values) ──────────────────────────
  let webMarkCount = 0;
  for (const ass of webAssessments) {
    for (const stu of students) {
      const rng = seededRandom(stu.id.charCodeAt(0) * 53 + ass.id.charCodeAt(0) * 23 + 9999);
      const base = studentAbility[stu.id];
      const bias = 0.03; // Web marks slightly higher on average
      const noise = (rng() - 0.5) * 0.12;
      const pct = Math.min(1.0, Math.max(0.10, base + bias + noise));
      const marksObtained = Math.floor(pct * ass.totalMarks);
      await prisma.mark.upsert({
        where: { assessmentId_studentId: { assessmentId: ass.id, studentId: stu.id } },
        update: { marksObtained },
        create: { assessmentId: ass.id, studentId: stu.id, marksObtained },
      });
      webMarkCount++;
    }
  }
  console.log(`  ✓ ${webMarkCount} integer marks inserted for ICE-3205`);

  // ── Attainment model: sum raw marks, threshold = floor(total * 60%) ──
  // CO attained if Σ(marks) >= floor(Σ(totalMarks) * 0.6)
  const CO_THRESH = 0.6;

  function computeCOResult(sid, co, assessments) {
    const linked = assessments.filter(a => a.coIds.includes(co.id));
    if (!linked.length) return null;
    let got = 0, total = 0, hasMark = false;
    for (const a of linked) {
      const mark = a.marks ? a.marks.find(m => m.studentId === sid) : null;
      if (mark == null) continue;
      hasMark = true;
      got   += mark.marksObtained;
      total += a.totalMarks;
    }
    if (!hasMark || total === 0) return null;
    const attainmentMark = Math.floor(total * CO_THRESH); // integer threshold
    const attained = got >= attainmentMark;
    return { totalObtained: got, totalPossible: total, attainmentMark, attained,
             percentage: (got / total) * 100, level: attained ? 'L3' : 'L0' };
  }

  function computePOResult(coMap, mappings, poId) {
    const rel = mappings.filter(m => m.programOutcomeId === poId && m.correlation);
    if (!rel.length) return null;
    const coResults = rel.map(m => coMap[m.courseOutcomeId]).filter(Boolean);
    if (!coResults.length) return null;
    const sumObt = coResults.reduce((s, r) => s + r.totalObtained, 0);
    const sumPos = coResults.reduce((s, r) => s + r.totalPossible, 0);
    if (sumPos === 0) return null;
    const attainmentMark = Math.floor(sumPos * CO_THRESH);
    const attained = sumObt >= attainmentMark;
    return { totalObtained: sumObt, totalPossible: sumPos, attainmentMark, attained,
             percentage: (sumObt / sumPos) * 100, level: attained ? 'L3' : 'L0' };
  }

  // ── Recompute SRE attainment ────────────────────────────────────
  const allSREAssessments = await prisma.assessment.findMany({
    where: { courseId: sre.id, deletedAt: null },
    include: { assessmentCOs: true, marks: true },
  });
  // Attach coIds for convenience
  allSREAssessments.forEach(a => { a.coIds = a.assessmentCOs.map(ac => ac.courseOutcomeId); });

  const allSREMappings = await prisma.coPoMapping.findMany({ where: { courseId: sre.id } });
  const sreEnrolments = await prisma.enrolment.findMany({ where: { courseId: sre.id } });
  const sreVersion = (await prisma.coPoMapping.findFirst({ where: { courseId: sre.id }, orderBy: { version: 'desc' } }))?.version || 1;
  const srePoIds = [...new Set(allSREMappings.map(m => m.programOutcomeId))];

  const coUpdates = [], poUpdates = [];

  for (const enrolment of sreEnrolments) {
    const sid = enrolment.studentId;
    const coMap = {};
    for (const co of sreCOs) {
      const result = computeCOResult(sid, co, allSREAssessments);
      if (!result) continue;
      coMap[co.id] = result;
      coUpdates.push(prisma.coAttainment.upsert({
        where: { courseOutcomeId_studentId: { courseOutcomeId: co.id, studentId: sid } },
        create: { courseOutcomeId: co.id, studentId: sid, courseId: sre.id, percentage: result.percentage, level: result.level, matrixVersion: sreVersion },
        update: { percentage: result.percentage, level: result.level, matrixVersion: sreVersion, computedAt: new Date() },
      }));
    }
    for (const pid of srePoIds) {
      const result = computePOResult(coMap, allSREMappings, pid);
      if (!result) continue;
      poUpdates.push(prisma.poAttainment.upsert({
        where: { programOutcomeId_studentId_courseId: { programOutcomeId: pid, studentId: sid, courseId: sre.id } },
        create: { programOutcomeId: pid, studentId: sid, courseId: sre.id, percentage: result.percentage, level: result.level, matrixVersion: sreVersion },
        update: { percentage: result.percentage, level: result.level, matrixVersion: sreVersion, computedAt: new Date() },
      }));
    }
  }

  // ── Recompute Web Technologies attainment ──────────────────────
  const allWebAssessments2 = await prisma.assessment.findMany({
    where: { courseId: web.id, deletedAt: null },
    include: { assessmentCOs: true, marks: true },
  });
  allWebAssessments2.forEach(a => { a.coIds = a.assessmentCOs.map(ac => ac.courseOutcomeId); });

  const allWebMappings = await prisma.coPoMapping.findMany({ where: { courseId: web.id } });
  const webEnrolments = await prisma.enrolment.findMany({ where: { courseId: web.id } });
  const webVersion = (await prisma.coPoMapping.findFirst({ where: { courseId: web.id }, orderBy: { version: 'desc' } }))?.version || 1;
  const webPoIds = [...new Set(allWebMappings.map(m => m.programOutcomeId))];

  for (const enrolment of webEnrolments) {
    const sid = enrolment.studentId;
    const coMap = {};
    for (const co of webCOs) {
      const result = computeCOResult(sid, co, allWebAssessments2);
      if (!result) continue;
      coMap[co.id] = result;
      coUpdates.push(prisma.coAttainment.upsert({
        where: { courseOutcomeId_studentId: { courseOutcomeId: co.id, studentId: sid } },
        create: { courseOutcomeId: co.id, studentId: sid, courseId: web.id, percentage: result.percentage, level: result.level, matrixVersion: webVersion },
        update: { percentage: result.percentage, level: result.level, matrixVersion: webVersion, computedAt: new Date() },
      }));
    }
    for (const pid of webPoIds) {
      const result = computePOResult(coMap, allWebMappings, pid);
      if (!result) continue;
      poUpdates.push(prisma.poAttainment.upsert({
        where: { programOutcomeId_studentId_courseId: { programOutcomeId: pid, studentId: sid, courseId: web.id } },
        create: { programOutcomeId: pid, studentId: sid, courseId: web.id, percentage: result.percentage, level: result.level, matrixVersion: webVersion },
        update: { percentage: result.percentage, level: result.level, matrixVersion: webVersion, computedAt: new Date() },
      }));
    }
  }

  const BATCH = 50;
  for (let i = 0; i < coUpdates.length; i += BATCH) await prisma.$transaction(coUpdates.slice(i, i + BATCH));
  for (let i = 0; i < poUpdates.length; i += BATCH) await prisma.$transaction(poUpdates.slice(i, i + BATCH));
  console.log(`  ✓ Attainment recomputed: ${coUpdates.length} CO records, ${poUpdates.length} PO records`);
  console.log('');
  console.log('  Attainment threshold: floor(total marks * 60%)  [integer]');

  console.log('  Recomputing attainment...');
  console.log('✅ All done - marks and attainment seeded!');
}

main().catch(console.error).finally(() => prisma.$disconnect());