const FacultyView = {
  _cid: null,

  // ── Course List ──────────────────────────────────────────────
  async courses() {
    document.getElementById('view-root').innerHTML = `
      <div class="page-hd"><div class="page-hd-left"><h1>My Courses</h1><div class="hd-sub">Courses assigned to you</div></div></div>
      <div id="fac-list">${loading()}</div>`;
    try {
      const list = await Api.getMyCourses();
      if (!list.length) {
        document.getElementById('fac-list').innerHTML = `<div class="empty-box"><div class="empty-ico">${ico('book',24)}</div><h3>No courses assigned</h3><p>Contact your administrator.</p></div>`;
        return;
      }
      document.getElementById('fac-list').innerHTML = `<div class="course-grid">${list.map(c => `
        <div class="course-card" onclick="FacultyView._openC('${c.id}','${c.name.replace(/'/g,'&#39;')}','${c.code}')">
          <div class="cc-icon">${ico('book',18)}</div>
          <div class="cc-code">${c.code}</div>
          <div class="cc-name">${c.name}</div>
          <div class="cc-meta"><span>${c.session?.name||''}</span><span>${c.creditHours||''} cr.</span></div>
        </div>`).join('')}</div>`;
    } catch(e) { document.getElementById('fac-list').innerHTML = `<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`; }
  },

  _openC(id, name, code) {
    this._cid = id;
    document.getElementById('view-root').innerHTML = `
      <div class="page-hd"><div class="page-hd-left">
        <button class="btn btn-ghost btn-sm mb2" onclick="FacultyView.courses()">${ico('back',13)} All Courses</button>
        <h1>${name}</h1><div class="hd-sub">${code}</div>
      </div></div>
      <div id="ctabs">
        <div class="tab-bar">
          <button class="tab-btn active" data-tab="tc-co">Course Outcomes</button>
          <button class="tab-btn" data-tab="tc-ass">Assessments</button>
          <button class="tab-btn" data-tab="tc-att">Attainment</button>
        </div>
        <div class="tab-pane active" id="tc-co"></div>
        <div class="tab-pane" id="tc-ass"></div>
        <div class="tab-pane" id="tc-att"></div>
      </div>`;
    initTabs('ctabs');
    this._loadCOs();
    document.querySelector('[data-tab="tc-ass"]').addEventListener('click',()=>this._loadAssess(),{once:true});
    document.querySelector('[data-tab="tc-att"]').addEventListener('click',()=>this._loadAttain(),{once:true});
  },

  // ── Course Outcomes (with PO mappings shown) ─────────────────
  async _loadCOs() {
    const el = document.getElementById('tc-co');
    el.innerHTML = `<div class="flex-between mb3"><span class="sec-title">Course Outcomes</span>
      <button class="btn btn-primary btn-sm" onclick="FacultyView._addCO()">${ico('plus')} Add CO</button></div>
      <div class="tbl-wrap"><table><thead><tr>
        <th>Code</th><th>Title</th><th>Bloom's</th><th>Profiles</th><th>Maps to POs</th><th class="td-r">Actions</th>
      </tr></thead><tbody id="co-tb">${tdLoad(6)}</tbody></table></div>`;
    try {
      const list = await Api.getCourseOutcomes(this._cid);
      document.getElementById('co-tb').innerHTML = list.length ? list.map(co => {
        const profiles = parseProfiles(co);
        const poLinks = (co.mappings||[])
          .filter(m => m.correlation)  // only show POs with an active mapping
          .map(m => `<span class="badge bg-blue" title="${m.programOutcome.title}">${m.programOutcome.code}</span>`)
          .join(' ') || '<span class="text-muted text-sm">None</span>';
        return `<tr>
          <td><span class="badge bg-green">${co.code}</span></td>
          <td><div class="fw7">${co.title}</div>${co.description?`<div class="text-sm text-muted">${co.description}</div>`:''}</td>
          <td>${co.bloomDomain?`<span class="badge bg-gray">${co.bloomDomain.charAt(0)}${co.bloomLevel||''}</span>`:'-'}</td>
          <td><div class="profile-chips">${renderProfileChips(profiles)}</div></td>
          <td>${poLinks}</td>
          <td class="td-r"><button class="icon-btn danger" onclick="FacultyView._delCO('${co.id}','${co.code}')">${ico('trash',13)}</button></td>
        </tr>`;
      }).join('') : tdEmpty('No COs yet. Add your first Course Outcome.',6);
    } catch(e) { document.getElementById('co-tb').innerHTML = tdEmpty(e.message,6); }
  },

  async _addCO() {
    // Fetch POs for this course's program
    const { programOutcomes: pos } = await Api.getMapping(this._cid);

    // Bloom's level labels per domain
    const bloomLevels = {
      COGNITIVE:    ['1 - Remember','2 - Understand','3 - Apply','4 - Analyse','5 - Evaluate','6 - Create'],
      AFFECTIVE:    ['1 - Receiving','2 - Responding','3 - Valuing','4 - Organising','5 - Characterising'],
      PSYCHOMOTOR:  ['1 - Imitation','2 - Manipulation','3 - Precision','4 - Articulation','5 - Naturalisation'],
    };

    showModal('Add Course Outcome', `
      <div class="form-row fr2 mb3">
        <div class="fg"><label>Code</label><input id="mco-code" placeholder="e.g. CO1"></div>
        <div class="fg"><label>Title</label><input id="mco-title" placeholder="Short learning outcome"></div>
      </div>
      <div class="fg mb3"><label>Description <span class="text-muted">(optional)</span></label><textarea id="mco-desc" rows="2"></textarea></div>

      <div class="divider"></div>
      <div class="form-row fr2 mb3">
        <div class="fg">
          <label>Bloom's Domain</label>
          <select id="mco-bloom" onchange="FacultyView._updateBloomLevels()">
            <option value="">- None -</option>
            <option value="COGNITIVE">Cognitive (6 levels)</option>
            <option value="AFFECTIVE">Affective (5 levels)</option>
            <option value="PSYCHOMOTOR">Psychomotor (5 levels)</option>
          </select>
        </div>
        <div class="fg">
          <label>Bloom's Level</label>
          <select id="mco-blvl" disabled>
            <option value="">Select domain first</option>
          </select>
        </div>
      </div>

      <div class="fg mb3">
        <label>Graduate Profiles <span class="text-muted">(select all that apply)</span></label>
        ${profileSelectorHTML()}
      </div>

      <div class="divider"></div>
      <div class="fg">
        <label>Maps to Program Outcomes</label>
        <p class="text-sm text-muted mb2">Check all POs this CO contributes to.</p>
        <div style="display:flex;flex-wrap:wrap;gap:8px">
          ${pos.map(po => `
            <label style="display:flex;align-items:center;gap:7px;padding:7px 12px;border:1.5px solid var(--border);border-radius:8px;cursor:pointer;font-size:12.5px;min-width:100px"
              onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='var(--border)'">
              <input type="checkbox" class="new-co-po" value="${po.id}"
                style="width:auto;accent-color:var(--green)">
              <span><strong>${po.code}</strong> <span class="text-muted">${po.title}</span></span>
            </label>`).join('')}
        </div>
        ${!pos.length ? '<p class="text-sm text-muted">No POs defined for this program yet.</p>' : ''}
      </div>`,
      `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button>
       <button class="btn btn-primary" onclick="FacultyView._saveCO()">${ico('save')} Add CO</button>`, true);

    // Store bloom levels for use by the onchange handler
    window._bloomLevels = bloomLevels;
  },

  _updateBloomLevels() {
    const domain = document.getElementById('mco-bloom').value;
    const sel = document.getElementById('mco-blvl');
    if (!domain) {
      sel.innerHTML = '<option value="">Select domain first</option>';
      sel.disabled = true;
      return;
    }
    const levels = window._bloomLevels[domain] || [];
    sel.innerHTML = '<option value="">- Select level -</option>' +
      levels.map((lbl, i) => `<option value="${i+1}">${lbl}</option>`).join('');
    sel.disabled = false;
  },

  async _saveCO() {
    const profiles = collectProfiles();
    const d = {
      code: document.getElementById('mco-code').value.trim(),
      title: document.getElementById('mco-title').value.trim(),
      description: document.getElementById('mco-desc').value.trim() || null,
      bloomDomain: document.getElementById('mco-bloom').value || null,
      bloomLevel: parseInt(document.getElementById('mco-blvl').value) || null,
      profileType: profiles.length ? profiles[0].type : null,
      profileCode: profiles.length ? JSON.stringify(profiles) : null,
    };
    if (!d.code || !d.title) return toast('Code and title required', 'err');
    try {
      // Create the CO
      const co = await Api.createCO(this._cid, d);

      // Save PO mappings for this CO - get all PO checkboxes
      const checkedPoIds = [...document.querySelectorAll('.new-co-po:checked')].map(cb => cb.value);
      if (checkedPoIds.length) {
        // Fetch existing mappings, merge with new ones
        const { mappings: existingMappings, programOutcomes: pos } = await Api.getMapping(this._cid);
        const newMappings = pos.map(po => ({
          courseOutcomeId: co.id,
          programOutcomeId: po.id,
          correlation: checkedPoIds.includes(po.id) ? 'STRONG' : null,
        }));
        // Also preserve existing mappings for OTHER COs
        const otherMappings = existingMappings
          .filter(m => m.courseOutcomeId !== co.id)
          .map(m => ({ courseOutcomeId: m.courseOutcomeId, programOutcomeId: m.programOutcomeId, correlation: m.correlation }));
        await Api.saveMapping(this._cid, [...otherMappings, ...newMappings]);
      }

      toast('CO added' + (checkedPoIds.length ? ' with PO mappings' : ''));
      closeModal();
      this._loadCOs();
    }
    catch(e) { toast(e.message, 'err'); }
  },

  async _delCO(coId, code) {
    if (!confirm(`Delete ${code}?`)) return;
    try { await Api.deleteCO(this._cid, coId); toast('Deleted'); this._loadCOs(); }
    catch(e) { toast(e.message, 'err'); }
  },

  // ── CO-PO Mapping (list, not matrix) ────────────────────────
  // CO-PO mapping is done inline when creating a CO (see _addCO / _saveCO)

  // ── Assessments (no weight, spreadsheet marks entry) ─────────
  async _loadAssess() {
    const el = document.getElementById('tc-ass');
    el.innerHTML = loading();
    try {
      const { assessments } = await Api.getAssessments(this._cid);
      el.innerHTML = `
        <div class="flex-between mb3">
          <div class="sec-title">Assessments</div>
          <button class="btn btn-primary btn-sm" onclick="FacultyView._addAssess()">${ico('plus')} Add Assessment</button>
        </div>
        <div class="tbl-wrap"><table><thead><tr>
          <th>Title</th><th>Type</th><th>Total Marks</th><th>Maps to COs</th><th class="td-r">Actions</th>
        </tr></thead>
        <tbody>${assessments.length ? assessments.map(a => `<tr>
          <td class="fw7">${a.title}</td>
          <td><span class="badge bg-gray">${a.type.replace(/_/g,' ')}</span></td>
          <td>${a.totalMarks}</td>
          <td>${(a.assessmentCOs||[]).map(ac=>`<span class="badge bg-green">${ac.courseOutcome?.code||''}</span>`).join(' ')||'-'}</td>
          <td class="td-r">
            <button class="btn btn-primary btn-xs" onclick="FacultyView._openMarksSheet('${a.id}','${a.title.replace(/'/g,'&#39;')}','${a.totalMarks}')">${ico('edit',13)} Enter Marks</button>
          </td>
        </tr>`).join('') : tdEmpty('No assessments yet',5)}</tbody></table></div>`;
    } catch(e) { el.innerHTML = `<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`; }
  },

  async _addAssess() {
    const cos = await Api.getCourseOutcomes(this._cid);
    const types = ['QUIZ','ASSIGNMENT','MID_TERM','FINAL','LAB','PROJECT','PRESENTATION','OTHER'];
    showModal('Add Assessment', `
      <div class="fg mb3"><label>Title</label><input id="ma-title" placeholder="e.g. Mid Term Examination"></div>
      <div class="form-row fr2 mb3">
        <div class="fg"><label>Type</label>
          <select id="ma-type">${types.map(t=>`<option value="${t}">${t.replace(/_/g,' ')}</option>`).join('')}</select></div>
        <div class="fg"><label>Total Marks</label><input id="ma-marks" type="number" value="100" min="1"></div>
      </div>
      <div class="fg"><label>Map to Course Outcomes</label>
        <div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:6px">
          ${cos.map(co=>`
            <label style="display:flex;align-items:center;gap:6px;padding:6px 11px;border:1.5px solid var(--border);border-radius:7px;cursor:pointer;font-size:12.5px">
              <input type="checkbox" class="co-chk" value="${co.id}" style="width:auto;accent-color:var(--green)">
              <strong>${co.code}</strong> <span class="text-muted">${co.title}</span>
            </label>`).join('')}
        </div>
      </div>`,
      `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button>
       <button class="btn btn-primary" onclick="FacultyView._saveAssess()">${ico('save')} Add</button>`);
  },

  async _saveAssess() {
    const d = {
      title: document.getElementById('ma-title').value.trim(),
      type: document.getElementById('ma-type').value,
      totalMarks: parseFloat(document.getElementById('ma-marks').value),
      courseOutcomeIds: [...document.querySelectorAll('.co-chk:checked')].map(c=>c.value),
    };
    if (!d.title) return toast('Title required', 'err');
    try { await Api.createAssessment(this._cid, d); toast('Assessment added'); closeModal(); this._loadAssess(); }
    catch(e) { toast(e.message, 'err'); }
  },

  // ── Marks - Spreadsheet style ────────────────────────────────
  async _openMarksSheet(aid, title, totalMarks) {
    document.getElementById('tc-ass').innerHTML = loading();
    try {
      const marks = await Api.getMarks(aid);
      const tm = parseFloat(totalMarks);

      document.getElementById('tc-ass').innerHTML = `
        <div class="flex-between mb3">
          <div>
            <button class="btn btn-ghost btn-sm mb2" onclick="FacultyView._loadAssess()">${ico('back',13)} Back to Assessments</button>
            <div class="sec-title">Marks - ${title} <span class="badge bg-gray">/${tm}</span></div>
            <p class="text-sm text-muted">Edit marks inline. Click Save when done.</p>
          </div>
          <button class="btn btn-primary" onclick="FacultyView._saveAllMarks('${aid}','${tm}')">${ico('save')} Save All Marks</button>
        </div>
        <div class="tbl-wrap">
          <table id="marks-sheet">
            <thead><tr>
              <th style="width:40px">#</th>
              <th>Roll No.</th>
              <th>Name</th>
              <th style="width:120px;text-align:center">Marks / ${tm}</th>
              <th style="width:80px;text-align:center">% Score</th>
              <th style="width:100px;text-align:center">Status</th>
            </tr></thead>
            <tbody>
              ${marks.map((m, i) => {
                const hasMark = m.marksObtained != null;
                const pct = hasMark ? (m.marksObtained / tm * 100).toFixed(1) : '';
                const pass = hasMark && m.marksObtained / tm >= 0.6;
                return `<tr id="mrow-${m.studentId}">
                  <td style="color:var(--text3)">${i+1}</td>
                  <td style="font-family:monospace;font-size:12px">${m.institutionalId}</td>
                  <td class="fw6">${m.name}</td>
                  <td style="text-align:center">
                    <input type="number" class="mark-inp" data-sid="${m.studentId}" data-tm="${tm}"
                      value="${hasMark ? m.marksObtained : ''}" min="0" max="${tm}" placeholder="-"
                      style="width:90px;text-align:center;font-weight:700"
                      oninput="FacultyView._onMarkInput(this)">
                  </td>
                  <td class="pct-cell" style="text-align:center;font-weight:700;color:${hasMark?(pass?'var(--l3)':'var(--l0)'):'var(--text4)'}">
                    ${pct ? pct+'%' : '-'}
                  </td>
                  <td class="status-cell" style="text-align:center">
                    ${hasMark ? `<span class="badge ${pass?'bg-green':'bg-red'}">${pass?'Attained':'Not Attained'}</span>` : '-'}
                  </td>
                </tr>`;
              }).join('')}
            </tbody>
          </table>
        </div>
        <div class="mt3 flex-between">
          <span class="text-sm text-muted">${marks.length} students</span>
          <button class="btn btn-primary" onclick="FacultyView._saveAllMarks('${aid}','${tm}')">${ico('save')} Save All Marks</button>
        </div>`;
    } catch(e) {
      document.getElementById('tc-ass').innerHTML = `<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`;
    }
  },

  _onMarkInput(inp) {
    const tm = parseFloat(inp.dataset.tm);
    const v = parseFloat(inp.value);
    const row = inp.closest('tr');
    const pctCell = row.querySelector('.pct-cell');
    const statusCell = row.querySelector('.status-cell');
    if (!inp.value || isNaN(v)) {
      pctCell.textContent = '-'; pctCell.style.color = 'var(--text4)';
      statusCell.innerHTML = '-';
      return;
    }
    const pct = (v / tm * 100).toFixed(1);
    const pass = v / tm >= 0.6;
    pctCell.textContent = pct + '%';
    pctCell.style.color = pass ? 'var(--l3)' : 'var(--l0)';
    statusCell.innerHTML = `<span class="badge ${pass?'bg-green':'bg-red'}">${pass?'Attained':'Not Attained'}</span>`;
  },

  async _saveAllMarks(aid, totalMarks) {
    const tm = parseFloat(totalMarks);
    const marks = [], invalid = [];
    document.querySelectorAll('.mark-inp').forEach(inp => {
      if (!inp.value) return;
      const v = parseFloat(inp.value);
      if (isNaN(v) || v < 0 || v > tm) { invalid.push(inp.dataset.sid); return; }
      marks.push({ studentId: inp.dataset.sid, marksObtained: v });
    });
    if (invalid.length) return toast(`Invalid marks for ${invalid.length} student(s)`, 'err');
    if (!marks.length) return toast('No marks entered', 'err');
    try {
      await Api.saveMarks(aid, marks);
      toast(`${marks.length} marks saved - attainment recomputed`);
    } catch(e) { toast(e.message, 'err'); }
  },

  // ── Attainment - % of students who attained ──────────────────
  async _loadAttain() {
    const el = document.getElementById('tc-att');
    el.innerHTML = loading();
    try {
      const _attRes = await Api.getCourseAttainment(this._cid);
      const coSummary = (_attRes && _attRes.coSummary) || [];
      const poSummary = (_attRes && _attRes.poSummary) || [];
      if (!coSummary.length && !poSummary.length) {
        el.innerHTML = `<div class="empty-box"><div class="empty-ico">${ico('chart',24)}</div>
          <h3>No attainment data yet</h3>
          <p>Enter marks and save CO-PO mappings to compute attainment.</p></div>`;
        return;
      }

      el.innerHTML = `
        <div class="sec-title mb3">Course Outcome Attainment</div>
        <div class="tbl-wrap mb4"><table>
          <thead><tr>
            <th>CO</th><th>Title</th>
            <th style="text-align:center">Students Attained</th>
            <th style="text-align:center">Total Students</th>
            <th style="min-width:180px">Attainment Rate</th>
          </tr></thead>
          <tbody>${coSummary.map(co => {
            const lvl = co.attainmentRate >= 60 ? 'L3' : 'L0';
            return `<tr>
              <td><span class="badge bg-green">${co.code}</span></td>
              <td>${co.title}</td>
              <td style="text-align:center;font-weight:700;color:var(--l3)">${co.attainedCount}</td>
              <td style="text-align:center;color:var(--text3)">${co.totalStudents}</td>
              <td>${attBar(co.attainmentRate, lvl)}</td>
            </tr>`;
          }).join('')}</tbody>
        </table></div>

        <div class="sec-title mb3">Program Outcome Attainment</div>
        <div class="tbl-wrap"><table>
          <thead><tr>
            <th>PO</th><th>Title</th>
            <th style="text-align:center">Students Attained</th>
            <th style="text-align:center">Total Students</th>
            <th style="min-width:180px">Attainment Rate</th>
          </tr></thead>
          <tbody>${poSummary.map(po => {
            const lvl = po.attainmentRate >= 60 ? 'L3' : 'L0';
            return `<tr>
              <td><span class="badge bg-blue">${po.code}</span></td>
              <td>${po.title}</td>
              <td style="text-align:center;font-weight:700;color:var(--l3)">${po.attainedCount}</td>
              <td style="text-align:center;color:var(--text3)">${po.totalStudents}</td>
              <td>${attBar(po.attainmentRate, lvl)}</td>
            </tr>`;
          }).join('')}</tbody>
        </table></div>`;
    } catch(e) { el.innerHTML = `<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`; }
  },

  // ── Reports ──────────────────────────────────────────────────
  async reports() {
    document.getElementById('view-root').innerHTML = `
      <div class="page-hd"><div class="page-hd-left"><h1>Reports</h1><div class="hd-sub">Generate course attainment reports</div></div></div>
      ${loading()}`;
    try {
      const list = await Api.getMyCourses();
      document.getElementById('view-root').innerHTML = `
        <div class="page-hd"><div class="page-hd-left"><h1>Reports</h1><div class="hd-sub">Download attainment data</div></div></div>
        <div class="card" style="max-width:500px"><div class="card-bd">
          <div class="fg mb4"><label>Course</label>
            <select id="rep-c">${list.map(c=>`<option value="${c.id}">${c.code} - ${c.name}</option>`).join('')}</select></div>
          <button class="btn btn-primary" onclick="FacultyView._genReport()">${ico('dl')} Download CSV</button>
          <div id="rep-res" class="mt3"></div>
        </div></div>`;
    } catch(e) { document.getElementById('view-root').innerHTML += `<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`; }
  },

  async _genReport() {
    const courseId = document.getElementById('rep-c').value;
    const el = document.getElementById('rep-res');
    el.innerHTML = `<div class="loading-box" style="padding:12px 0;justify-content:flex-start"><div class="spin"></div> Generating…</div>`;
    try {
      // Get attainment data and build CSV client-side
      const _repRes = await Api.getCourseAttainment(courseId);
      const coSummary = (_repRes && _repRes.coSummary) || [];
      const poSummary = (_repRes && _repRes.poSummary) || [];
      if (!coSummary.length && !poSummary.length) { el.innerHTML = '<div class="alert alert-warn">No attainment data yet for this course.</div>'; return; }
      const rows = [
        ['Type','Code','Title','Attained Students','Total Students','Attainment Rate (%)'],
        ...coSummary.map(r => ['CO', r.code, r.title, r.attainedCount, r.totalStudents, (+(r.attainmentRate||0)).toFixed(1)]),
        ['','','','','',''],
        ...poSummary.map(r => ['PO', r.code, r.title, r.attainedCount, r.totalStudents, (+(r.attainmentRate||0)).toFixed(1)]),
      ];
      const csv = rows.map(r => r.map(v => '"'+String(v).replace(/"/g,'""')+'"').join(',')).join('\n');
      const blob = new Blob([csv], { type:'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = 'attainment_report.csv'; a.click();
      URL.revokeObjectURL(url);
      el.innerHTML = `<div class="alert alert-success"><span class="alert-icon">✓</span>Downloaded successfully.</div>`;
    } catch(e) { el.innerHTML = `<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`; }
  },
};
