/**
 * Attainment threshold — 60% of weighted marks to pass a CO.
 * This is the single binary threshold used throughout the system.
 */
const CO_ATTAINMENT_THRESHOLD = 0.60;   // 60%
const PO_ATTAINMENT_THRESHOLD = 0.60;   // 60% of weighted CO coverage

/**
 * Correlation enum → numeric weight (used for PO computation)
 */
const correlationWeight = { WEAK: 1, MODERATE: 2, STRONG: 3 };

/**
 * Binary CO attainment per student.
 *
 * Formula:
 *   ratio = Σ(marks × weight) / Σ(totalMarks × weight)   for all assessments linked to this CO
 *   attained = ratio >= 0.60
 *
 * Returns { attained: bool, percentage: number 0-100 }
 */
function computeCOAttainment(studentId, co, assessments) {
  const linked = assessments.filter(a =>
    a.assessmentCOs.some(aco => aco.courseOutcomeId === co.id)
  );
  if (!linked.length) return null;

  let weightedMarks = 0;
  let weightedTotal = 0;
  let hasMark = false;

  for (const assessment of linked) {
    const mark = assessment.marks.find(m => m.studentId === studentId);
    if (!mark) continue;
    hasMark = true;
    weightedMarks += mark.marksObtained * assessment.weight;
    weightedTotal += assessment.totalMarks * assessment.weight;
  }

  if (!hasMark || weightedTotal === 0) return null;

  const ratio = weightedMarks / weightedTotal;
  const percentage = ratio * 100;
  const attained = ratio >= CO_ATTAINMENT_THRESHOLD;

  // Store as 100 (attained) or the raw percentage (for display) but level is binary
  return {
    percentage,          // raw % for display (e.g. 73.3%)
    attained,            // binary decision
    level: attained ? 'L3' : 'L0',   // L3 = Attained, L0 = Not Attained
  };
}

/**
 * Binary PO attainment per student.
 *
 * Formula:
 *   weightedAttained = Σ corr(COᵢ, PO) × attained(COᵢ)
 *   weightedTotal    = Σ corr(COᵢ, PO)
 *   ratio = weightedAttained / weightedTotal
 *   attained = ratio >= 0.60
 *
 * Returns { attained: bool, percentage: number 0-100, level: string }
 */
function computePOAttainment(coAttainmentMap, mappings, programOutcomeId) {
  const relevant = mappings.filter(
    m => m.programOutcomeId === programOutcomeId && m.correlation
  );
  if (!relevant.length) return null;

  let weightedAttained = 0;
  let weightedTotal = 0;

  for (const mapping of relevant) {
    const coResult = coAttainmentMap[mapping.courseOutcomeId];
    if (coResult === undefined) continue;
    const w = correlationWeight[mapping.correlation] || 0;
    weightedAttained += w * (coResult.attained ? 1 : 0);
    weightedTotal += w;
  }

  if (weightedTotal === 0) return null;

  const ratio = weightedAttained / weightedTotal;
  const percentage = ratio * 100;
  const attained = ratio >= PO_ATTAINMENT_THRESHOLD;

  return {
    percentage,          // % of weighted COs attained (for display)
    attained,
    level: attained ? 'L3' : 'L0',
  };
}

/** Binary level: Attained (L3) or Not Attained (L0). Threshold fixed at 60%. */
function getLevel(percentage) {
  return percentage >= CO_ATTAINMENT_THRESHOLD * 100 ? 'L3' : 'L0';
}

module.exports = {
  computeCOAttainment,
  computePOAttainment,
  correlationWeight,
  getLevel,
  CO_ATTAINMENT_THRESHOLD,
  PO_ATTAINMENT_THRESHOLD,
};
