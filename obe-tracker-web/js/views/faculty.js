const FacultyView={
  _cid:null,_matrix:{},

  async courses(){
    document.getElementById('view-root').innerHTML=`
      <div class="page-hd"><div class="page-hd-left"><h1>My Courses</h1><div class="hd-sub">Courses currently assigned to you</div></div></div>
      <div id="fac-list">${loading()}</div>`;
    try{
      const l=await Api.getMyCourses();
      if(!l.length){document.getElementById('fac-list').innerHTML=`<div class="empty-box"><div class="empty-ico">${ico('book',24)}</div><h3>No courses assigned</h3><p>Contact your administrator to get assigned.</p></div>`;return}
      document.getElementById('fac-list').innerHTML=`<div class="course-grid">${l.map(c=>`
        <div class="course-card" onclick="FacultyView._openC('${c.id}','${c.name.replace(/'/g,'&#39;')}','${c.code}')">
          <div class="cc-icon">${ico('book',18)}</div>
          <div class="cc-code">${c.code}</div>
          <div class="cc-name">${c.name}</div>
          <div class="cc-meta"><span>${c.session?.name||''}</span><span>${c.creditHours} cr.</span><span>${c.program?.code||''}</span></div>
        </div>`).join('')}</div>`;
    }catch(e){document.getElementById('fac-list').innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },

  _openC(id,name,code){
    this._cid=id;
    document.getElementById('view-root').innerHTML=`
      <div class="page-hd"><div class="page-hd-left">
        <button class="btn btn-ghost btn-sm mb2" onclick="FacultyView.courses()">${ico('back',13)} All Courses</button>
        <h1>${name}</h1><div class="hd-sub">${code}</div>
      </div></div>
      <div id="ctabs">
        <div class="tab-bar">
          <button class="tab-btn active" data-tab="tc-co">Course Outcomes</button>
          <button class="tab-btn" data-tab="tc-map">CO–PO Matrix</button>
          <button class="tab-btn" data-tab="tc-ass">Assessments</button>
          <button class="tab-btn" data-tab="tc-att">Attainment</button>
        </div>
        <div class="tab-pane active" id="tc-co"></div>
        <div class="tab-pane" id="tc-map"></div>
        <div class="tab-pane" id="tc-ass"></div>
        <div class="tab-pane" id="tc-att"></div>
      </div>`;
    initTabs('ctabs');this._loadCOs();
    document.querySelector('[data-tab="tc-map"]').addEventListener('click',()=>this._loadMatrix(),{once:true});
    document.querySelector('[data-tab="tc-ass"]').addEventListener('click',()=>this._loadAssess(),{once:true});
    document.querySelector('[data-tab="tc-att"]').addEventListener('click',()=>this._loadAttain(),{once:true});
  },

  // ── COs ───────────────────────────────────────────────────
  async _loadCOs(){
    const el=document.getElementById('tc-co');
    el.innerHTML=`<div class="flex-between mb3"><span class="sec-title">Course Outcomes</span><button class="btn btn-primary btn-sm" onclick="FacultyView._addCO()">${ico('plus')} Add CO</button></div>
      <div class="tbl-wrap"><table><thead><tr><th>Code</th><th>Title</th><th>Bloom's</th><th>Profiles</th><th class="td-r">Actions</th></tr></thead><tbody id="co-tb">${tdLoad(5)}</tbody></table></div>`;
    try{
      const l=await Api.getCourseOutcomes(this._cid);
      document.getElementById('co-tb').innerHTML=l.length?l.map(co=>{
        const profiles=parseProfiles(co);
        return`<tr>
          <td><span class="badge bg-green">${co.code}</span></td>
          <td><div class="fw7">${co.title}</div>${co.description?`<div class="text-sm text-muted">${co.description}</div>`:''}</td>
          <td>${co.bloomDomain?`<span class="badge bg-blue">${co.bloomDomain.charAt(0)}${co.bloomLevel||''}</span>`:'—'}</td>
          <td><div class="profile-chips">${renderProfileChips(profiles)}</div></td>
          <td class="td-r"><button class="icon-btn danger" onclick="FacultyView._delCO('${co.id}','${co.code}')">${ico('trash',13)}</button></td>
        </tr>`;
      }).join(''):tdEmpty('No course outcomes yet. Add your first CO.',5);
    }catch(e){document.getElementById('co-tb').innerHTML=tdEmpty(e.message,5)}
  },

  _addCO(){
    showModal('Add Course Outcome',`
      <div class="form-row fr2 mb3">
        <div class="fg"><label>Code</label><input id="mco-code" placeholder="e.g. CO1"></div>
        <div class="fg"><label>Title</label><input id="mco-title" placeholder="Short learning outcome"></div>
      </div>
      <div class="fg mb3"><label>Description <span class="text-muted">(optional)</span></label><textarea id="mco-desc" rows="2"></textarea></div>
      <div class="divider"></div>
      <div class="form-row fr2 mb3">
        <div class="fg"><label>Bloom's Domain</label>
          <select id="mco-bloom"><option value="">None</option><option>COGNITIVE</option><option>AFFECTIVE</option><option>PSYCHOMOTOR</option></select></div>
        <div class="fg"><label>Bloom's Level</label>
          <select id="mco-blvl"><option value="">None</option>${[1,2,3,4,5,6].map(n=>`<option>${n}</option>`).join('')}</select></div>
      </div>
      <div class="fg"><label>Graduate Profiles <span class="text-muted">(select all that apply)</span></label>
        ${profileSelectorHTML()}
      </div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="FacultyView._saveCO()">${ico('save')} Add CO</button>`,true);
  },

  async _saveCO(){
    const profiles=collectProfiles();
    const d={
      code:document.getElementById('mco-code').value.trim(),
      title:document.getElementById('mco-title').value.trim(),
      description:document.getElementById('mco-desc').value.trim()||null,
      bloomDomain:document.getElementById('mco-bloom').value||null,
      bloomLevel:parseInt(document.getElementById('mco-blvl').value)||null,
      profileType:profiles.length?profiles[0].type:null,
      profileCode:profiles.length?JSON.stringify(profiles):null,
    };
    if(!d.code||!d.title)return toast('Code and title required','err');
    try{await Api.createCO(this._cid,d);toast('CO added');closeModal();this._loadCOs()}catch(e){toast(e.message,'err')}
  },

  async _delCO(coId,code){if(!confirm(`Delete ${code}?`))return;
    try{await Api.deleteCO(this._cid,coId);toast('Deleted');this._loadCOs()}catch(e){toast(e.message,'err')}},

  // ── Matrix ────────────────────────────────────────────────
  async _loadMatrix(){
    const el=document.getElementById('tc-map');el.innerHTML=loading();
    try{
      const{courseOutcomes:cos,programOutcomes:pos,mappings}=await Api.getMapping(this._cid);
      this._matrix={};mappings.forEach(m=>{if(!this._matrix[m.courseOutcomeId])this._matrix[m.courseOutcomeId]={};this._matrix[m.courseOutcomeId][m.programOutcomeId]=m.correlation});
      if(!cos.length||!pos.length){el.innerHTML=`<div class="empty-box"><div class="empty-ico">${ico('grid',24)}</div><h3>Add COs and ensure POs are defined</h3><p>Set up Course Outcomes first.</p></div>`;return}
      const vals={null:'–',WEAK:'1',MODERATE:'2',STRONG:'3'};
      el.innerHTML=`
        <div class="flex-between mb3">
          <div><div class="sec-title">CO–PO Mapping Matrix</div><p class="text-sm text-muted">Click cells to cycle: – → 1 (Weak) → 2 (Moderate) → 3 (Strong)</p></div>
          <button class="btn btn-primary" onclick="FacultyView._saveMatrix()">${ico('save')} Save Matrix</button>
        </div>
        <div class="matrix-scroll"><table class="mtr"><thead><tr>
          <td style="background:transparent;min-width:110px"></td>
          ${pos.map(p=>`<td class="mtr-po" title="${p.title}">${p.code}</td>`).join('')}
        </tr></thead><tbody>${cos.map(co=>`<tr>
          <td class="mtr-co" title="${co.title}">${co.code} <span style="opacity:.55;font-weight:400;font-size:10px">${co.title.substring(0,16)}…</span></td>
          ${pos.map(po=>{const v=(this._matrix[co.id]||{})[po.id]||null;return`<td class="mtr-cell" data-co="${co.id}" data-po="${po.id}" data-v="${v||''}" onclick="FacultyView._cycleCell(this)">${vals[v]||'–'}</td>`}).join('')}
        </tr>`).join('')}</tbody></table></div>
        <div style="display:flex;gap:14px;margin-top:12px;flex-wrap:wrap">
          ${[['var(--surface2)','var(--border)','No mapping'],['#D1FAE5','#6EE7B7','1 — Weak'],['#6EE7B7','#34D399','2 — Moderate'],['#059669','#047857','3 — Strong']].map(([bg,bd,lbl])=>`
          <div style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--text3)"><div style="width:14px;height:14px;border-radius:3px;background:${bg};border:1px solid ${bd}"></div>${lbl}</div>`).join('')}
        </div>`;
    }catch(e){el.innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },
  _cycleCell(td){const vals=[null,'WEAK','MODERATE','STRONG'],labels={null:'–',WEAK:'1',MODERATE:'2',STRONG:'3'};const cur=td.dataset.v||null;const next=vals[(vals.indexOf(cur&&cur!==''?cur:null)+1)%4];td.dataset.v=next||'';td.textContent=labels[next];if(!this._matrix[td.dataset.co])this._matrix[td.dataset.co]={};this._matrix[td.dataset.co][td.dataset.po]=next},
  async _saveMatrix(){const mappings=[];document.querySelectorAll('.mtr-cell').forEach(td=>mappings.push({courseOutcomeId:td.dataset.co,programOutcomeId:td.dataset.po,correlation:td.dataset.v||null}));
    try{await Api.saveMapping(this._cid,mappings);toast('Matrix saved — attainment recomputed')}catch(e){toast(e.message,'err')}},

  // ── Assessments ──────────────────────────────────────────
  async _loadAssess(){
    const el=document.getElementById('tc-ass');el.innerHTML=loading();
    try{
      const{assessments,weightSum,weightWarning}=await Api.getAssessments(this._cid);
      el.innerHTML=`
        <div class="flex-between mb3">
          <div><div class="sec-title">Assessments</div>
            <p class="text-sm" style="color:${weightWarning?'var(--amber)':'var(--green)'}">Weight total: <strong>${(weightSum||0).toFixed(1)}%</strong> ${weightWarning?'⚠ Should be 100%':'✓'}</p></div>
          <button class="btn btn-primary btn-sm" onclick="FacultyView._addAssess()">${ico('plus')} Add</button>
        </div>
        ${weightWarning?`<div class="alert alert-warn mb3"><span class="alert-icon">⚠</span>Total weight is ${(weightSum||0).toFixed(1)}%. Needs to be 100% for correct attainment.</div>`:''}
        <div class="tbl-wrap"><table><thead><tr><th>Title</th><th>Type</th><th>Marks</th><th>Weight</th><th>Maps to COs</th><th class="td-r">Actions</th></tr></thead>
        <tbody>${assessments.length?assessments.map(a=>`<tr>
          <td class="fw7">${a.title}</td>
          <td><span class="badge bg-gray">${a.type.replace(/_/g,' ')}</span></td>
          <td>${a.totalMarks}</td><td><strong>${a.weight}%</strong></td>
          <td>${(a.assessmentCOs||[]).map(ac=>`<span class="badge bg-green">${ac.courseOutcome?.code||''}</span>`).join(' ')||'—'}</td>
          <td class="td-r"><button class="btn btn-primary btn-xs" onclick="FacultyView._openMarks('${a.id}','${a.title.replace(/'/g,'&#39;')}','${a.totalMarks}')">${ico('edit',13)} Marks</button></td>
        </tr>`).join(''):tdEmpty('No assessments yet',6)}</tbody></table></div>`;
    }catch(e){el.innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },
  async _addAssess(){
    const cos=await Api.getCourseOutcomes(this._cid);
    const types=['QUIZ','ASSIGNMENT','MID_TERM','FINAL','LAB','PROJECT','PRESENTATION','OTHER'];
    showModal('Add Assessment',`
      <div class="fg mb3"><label>Title</label><input id="ma-title" placeholder="e.g. Mid Term Examination"></div>
      <div class="form-row fr3 mb3">
        <div class="fg"><label>Type</label><select id="ma-type">${types.map(t=>`<option value="${t}">${t.replace(/_/g,' ')}</option>`).join('')}</select></div>
        <div class="fg"><label>Total Marks</label><input id="ma-marks" type="number" value="100" min="1"></div>
        <div class="fg"><label>Weight %</label><input id="ma-wt" type="number" value="25" min="0" max="100"></div>
      </div>
      <div class="fg"><label>Map to Course Outcomes</label>
        <div style="display:flex;flex-wrap:wrap;gap:7px;margin-top:6px">${cos.map(co=>`
          <label style="display:flex;align-items:center;gap:6px;padding:6px 11px;border:1.5px solid var(--border);border-radius:7px;cursor:pointer;font-size:12.5px;transition:all .12s" onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='var(--border)'">
            <input type="checkbox" class="co-chk" value="${co.id}" style="width:auto;accent-color:var(--green)">
            <strong>${co.code}</strong> <span class="text-muted">${co.title}</span>
          </label>`).join('')}</div>
      </div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="FacultyView._saveAssess()">${ico('save')} Add</button>`)},
  async _saveAssess(){
    const d={title:document.getElementById('ma-title').value.trim(),type:document.getElementById('ma-type').value,totalMarks:+document.getElementById('ma-marks').value,weight:+document.getElementById('ma-wt').value,courseOutcomeIds:[...document.querySelectorAll('.co-chk:checked')].map(c=>c.value)};
    if(!d.title)return toast('Title required','err');
    try{await Api.createAssessment(this._cid,d);toast('Assessment added');closeModal();this._loadAssess()}catch(e){toast(e.message,'err')}},
  _onMarkInput(inp) {
    const tm = parseFloat(inp.dataset.tm);
    const pct = inp.value ? ((inp.value / tm * 100).toFixed(0) + '%') : '—';
    const ok  = inp.value && parseFloat(inp.value) / tm >= 0.6;
    const pc  = inp.closest('tr').querySelector('.pct-cell');
    pc.textContent  = pct;
    pc.style.color  = inp.value ? (ok ? 'var(--l3)' : 'var(--l0)') : 'var(--text4)';
  },
  async _openMarks(aid, title, totalMarks) {
    showModal('Marks — ' + title, loading(), '', true);
    try {
      const marks = await Api.getMarks(aid);
      if (!marks.length) {
        document.getElementById('modal-body').innerHTML =
          '<div class="empty-box"><div class="empty-ico">' + ico('users',24) + '</div><h3>No students enrolled</h3></div>';
        document.getElementById('modal-ft').innerHTML = '<button class="btn btn-ghost" onclick="closeModal()">Close</button>';
        document.getElementById('modal-ft').classList.remove('hidden');
        return;
      }
      const tm = parseFloat(totalMarks);
      const ths = 'padding:9px 14px;font-size:11px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--text3);border-bottom:1px solid var(--border)';
      let rows = '';
      marks.forEach(function(m, i) {
        const hasMark = m.marksObtained != null;
        const pct = hasMark ? ((m.marksObtained / tm * 100).toFixed(0) + '%') : '—';
        const col = hasMark ? (m.marksObtained / tm >= 0.6 ? 'var(--l3)' : 'var(--l0)') : 'var(--text4)';
        const bg  = i % 2 ? 'var(--surface2)' : 'var(--surface)';
        const val = hasMark ? m.marksObtained : '';
        rows +=
          '<tr style="background:' + bg + '">' +
          '<td style="padding:9px 14px;font-size:12px;color:var(--text3);border-bottom:1px solid var(--border)">' + (i+1) + '</td>' +
          '<td style="padding:9px 14px;font-family:monospace;font-size:12px;font-weight:600;color:var(--text2);border-bottom:1px solid var(--border)">' + (m.institutionalId || '—') + '</td>' +
          '<td style="padding:9px 14px;font-size:13px;font-weight:600;color:var(--text);border-bottom:1px solid var(--border)">' + m.name + '</td>' +
          '<td style="padding:6px 14px;border-bottom:1px solid var(--border)">' +
            '<input type="number" class="mark-inp" data-sid="' + m.studentId + '" data-tm="' + tm + '" value="' + val + '" min="0" max="' + tm + '" placeholder="—" style="width:90px;text-align:center;font-weight:700" oninput="FacultyView._onMarkInput(this)">' +
          '</td>' +
          '<td class="pct-cell" style="padding:9px 14px;text-align:right;font-size:12.5px;font-weight:700;border-bottom:1px solid var(--border);color:' + col + '">' + pct + '</td>' +
          '</tr>';
      });
      document.getElementById('modal-body').innerHTML =
        '<div style="display:flex;justify-content:space-between;margin-bottom:12px">' +
          '<span style="font-size:13px;color:var(--text3)">Total marks: <strong>' + tm + '</strong></span>' +
          '<span style="font-size:13px;color:var(--text3)">' + marks.length + ' students</span>' +
        '</div>' +
        '<div style="overflow-x:auto;border:1px solid var(--border);border-radius:var(--r)">' +
          '<table style="width:100%;border-collapse:collapse">' +
            '<thead style="background:var(--surface2)"><tr>' +
              '<th style="' + ths + '">#</th>' +
              '<th style="' + ths + '">Roll No.</th>' +
              '<th style="' + ths + '">Name</th>' +
              '<th style="' + ths + ';text-align:center;width:130px">Marks / ' + tm + '</th>' +
              '<th style="' + ths + ';text-align:right;width:65px">%</th>' +
            '</tr></thead>' +
            '<tbody>' + rows + '</tbody>' +
          '</table>' +
        '</div>';
      document.getElementById('modal-ft').innerHTML =
        '<button class="btn btn-ghost" onclick="closeModal()">Cancel</button>' +
        '<button class="btn btn-primary" data-aid="' + aid + '" data-tm="' + tm + '" onclick="FacultyView._doSaveMarks(this)">' + ico('save') + ' Save All Marks</button>';
      document.getElementById('modal-ft').classList.remove('hidden');
    } catch(e) {
      document.getElementById('modal-body').innerHTML =
        '<div class="alert alert-error"><span class="alert-icon">⚠</span>' + e.message + '</div>';
    }
  },
  _doSaveMarks(btn) {
    FacultyView._saveMarks(btn.dataset.aid, btn.dataset.tm);
  },
  async _saveMarks(aid,totalMarks){
    const marks=[],bad=[];
    document.querySelectorAll('.mark-inp').forEach(inp=>{if(!inp.value)return;const v=+inp.value;if(isNaN(v)||v<0||v>+totalMarks){bad.push(inp.dataset.sid);return}marks.push({studentId:inp.dataset.sid,marksObtained:v})});
    if(bad.length)return toast(`Invalid marks for ${bad.length} student(s)`,'err');
    try{await Api.saveMarks(aid,marks);toast('Marks saved — attainment recomputed');closeModal()}catch(e){toast(e.message,'err')}},

  // ── Attainment ────────────────────────────────────────────
  async _loadAttain(){
    const el=document.getElementById('tc-att');el.innerHTML=loading();
    try{
      const{coAttainments,poAttainments}=await Api.getCourseAttainment(this._cid);
      if(!coAttainments.length&&!poAttainments.length){el.innerHTML=`<div class="empty-box"><div class="empty-ico">${ico('chart',24)}</div><h3>No attainment data</h3><p>Enter marks and save the CO–PO matrix first.</p></div>`;return}
      const avg=arr=>arr.reduce((s,v)=>s+v,0)/arr.length;
      const coMap={},poMap={};
      coAttainments.forEach(a=>{if(!coMap[a.courseOutcomeId])coMap[a.courseOutcomeId]={co:a.courseOutcome,pcts:[]};coMap[a.courseOutcomeId].pcts.push(a.percentage)});
      poAttainments.forEach(a=>{if(!poMap[a.programOutcomeId])poMap[a.programOutcomeId]={po:a.programOutcome,pcts:[]};poMap[a.programOutcomeId].pcts.push(a.percentage)});
      el.innerHTML=`
        <div class="sec-title mb3">Course Outcome Attainment</div>
        <div class="tbl-wrap mb4"><table><thead><tr><th>CO</th><th>Title</th><th style="min-width:200px">Attainment</th><th>Level</th></tr></thead>
        <tbody>${Object.values(coMap).map(({co,pcts})=>{const p=avg(pcts),l=p>=60?'L3':'L0';return`<tr><td><span class="badge bg-green">${co.code}</span></td><td>${co.title}</td><td>${attBar(p,l)}</td><td>${levelBadge(l,p)}</td></tr>`}).join('')}</tbody></table></div>
        <div class="sec-title mb3">Program Outcome Attainment</div>
        <div class="tbl-wrap"><table><thead><tr><th>PO</th><th>Title</th><th style="min-width:200px">Attainment</th><th>Level</th></tr></thead>
        <tbody>${Object.values(poMap).map(({po,pcts})=>{const p=avg(pcts),l=p>=60?'L3':'L0';return`<tr><td><span class="badge bg-blue">${po.code}</span></td><td>${po.title}</td><td>${attBar(p,l)}</td><td>${levelBadge(l,p)}</td></tr>`}).join('')}</tbody></table></div>`;
    }catch(e){el.innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },

  // ── Reports ───────────────────────────────────────────────
  async reports(){
    document.getElementById('view-root').innerHTML=`<div class="page-hd"><div class="page-hd-left"><h1>Reports</h1><div class="hd-sub">Generate attainment reports</div></div></div>${loading()}`;
    try{
      const l=await Api.getMyCourses();
      document.getElementById('view-root').innerHTML=`
        <div class="page-hd"><div class="page-hd-left"><h1>Reports</h1><div class="hd-sub">Generate and download course attainment reports</div></div></div>
        <div class="card" style="max-width:500px"><div class="card-bd">
          <div class="fg mb3"><label>Course</label><select id="rep-c">${l.map(c=>`<option value="${c.id}">${c.code} — ${c.name}</option>`).join('')}</select></div>
          <div class="fg mb4"><label>Format</label>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:6px">
              <label style="display:flex;align-items:flex-start;gap:9px;padding:12px;border:1.5px solid var(--green);border-radius:8px;cursor:pointer;background:var(--green-xl)"><input type="radio" name="rfmt" value="PDF" checked style="width:auto;accent-color:var(--green);margin-top:2px"><div><div class="fw7">PDF</div><div class="text-sm text-muted">Formatted, printable report</div></div></label>
              <label style="display:flex;align-items:flex-start;gap:9px;padding:12px;border:1.5px solid var(--border);border-radius:8px;cursor:pointer"><input type="radio" name="rfmt" value="CSV" style="width:auto;accent-color:var(--green);margin-top:2px"><div><div class="fw7">CSV</div><div class="text-sm text-muted">Raw data, Excel-compatible</div></div></label>
            </div>
          </div>
          <button class="btn btn-primary" onclick="FacultyView._genReport()">${ico('dl')} Generate Report</button>
          <div id="rep-res" class="mt3"></div>
        </div></div>`;
    }catch(e){document.getElementById('view-root').innerHTML+=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },
  async _genReport(){
    const courseId=document.getElementById('rep-c').value,format=document.querySelector('input[name="rfmt"]:checked').value;
    const el=document.getElementById('rep-res');el.innerHTML=`<div class="loading-box" style="padding:12px 0;justify-content:flex-start"><div class="spin"></div> Generating…</div>`;
    try{const d=await Api.post(`/reports/course/${courseId}`,{format});el.innerHTML=`<div class="alert alert-success"><span class="alert-icon">✓</span>Ready! <a href="http://localhost:3000${d.downloadUrl}" target="_blank" class="btn btn-secondary btn-sm" style="margin-left:8px">${ico('dl',13)} Download</a></div>`}
    catch(e){el.innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}},
};
