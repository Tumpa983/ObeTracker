/**
 * NEW Attainment Model (as specified):
 *
 * CO: Sum all marks for tests that involve this CO.
 *     If sum >= attainment threshold (60% of total possible marks), CO is achieved.
 *
 * PO: Sum all CO marks across multiple courses that map to this PO.
 *     If sum of all involved CO marks >= sum of CO attainment marks, PO is achieved.
 */

const CO_THRESHOLD_PCT = 0.60; // 60%

/**
 * Compute CO attainment for one student.
 * Sum all raw marks across assessments linked to this CO.
 * Attained if sum >= 60% of total possible marks for those assessments.
 */
function computeCOAttainment(studentId, co, assessments) {
  const linked = assessments.filter(a =>
    a.assessmentCOs.some(aco => aco.courseOutcomeId === co.id)
  );
  if (!linked.length) return null;

  let totalObtained = 0;
  let totalPossible = 0;
  let hasMark = false;

  for (const a of linked) {
    const mark = a.marks.find(m => m.studentId === studentId);
    if (!mark) continue;
    hasMark = true;
    totalObtained += mark.marksObtained;
    totalPossible += a.totalMarks;
  }

  if (!hasMark || totalPossible === 0) return null;

  const attainmentMark = totalPossible * CO_THRESHOLD_PCT; // the minimum marks needed
  const attained = totalObtained >= attainmentMark;
  const percentage = (totalObtained / totalPossible) * 100;

  return {
    percentage,
    totalObtained,
    totalPossible,
    attainmentMark,
    attained,
    level: attained ? 'L3' : 'L0',
  };
}

/**
 * Compute PO attainment for one student across all courses.
 * coResultsForPO = array of { totalObtained, totalPossible } for each CO mapped to this PO.
 * Attained if sum(totalObtained) >= 60% of sum(totalPossible).
 */
function computePOAttainmentFromCOs(coResults) {
  if (!coResults.length) return null;

  const sumObtained = coResults.reduce((s, r) => s + r.totalObtained, 0);
  const sumPossible = coResults.reduce((s, r) => s + r.totalPossible, 0);

  if (sumPossible === 0) return null;

  const attainmentMark = sumPossible * CO_THRESHOLD_PCT;
  const attained = sumObtained >= attainmentMark;
  const percentage = (sumObtained / sumPossible) * 100;

  return {
    percentage,
    totalObtained: sumObtained,
    totalPossible: sumPossible,
    attainmentMark,
    attained,
    level: attained ? 'L3' : 'L0',
  };
}

// PO attainment: sum marks from all COs mapped to this PO (correlation strength ignored)
function computePOAttainment(coAttainmentMap, mappings, programOutcomeId) {
  // Include any mapping with a non-null correlation (checkbox = checked = 'STRONG')
  const relevant = mappings.filter(m => m.programOutcomeId === programOutcomeId && m.correlation);
  if (!relevant.length) return null;

  const coResults = relevant
    .map(m => coAttainmentMap[m.courseOutcomeId])
    .filter(Boolean);

  return computePOAttainmentFromCOs(coResults);
}

function getLevel(percentage) {
  return percentage >= CO_THRESHOLD_PCT * 100 ? 'L3' : 'L0';
}

const correlationWeight = { WEAK: 1, MODERATE: 2, STRONG: 3 };

module.exports = {
  computeCOAttainment,
  computePOAttainment,
  computePOAttainmentFromCOs,
  correlationWeight,
  getLevel,
  CO_THRESHOLD_PCT,
};
