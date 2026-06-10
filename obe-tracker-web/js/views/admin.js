const AdminView={
  // ── Dashboard ──────────────────────────────────────────────
  async dash(){
    const vr=document.getElementById('view-root');
    vr.innerHTML=`<div class="page-hd"><div class="page-hd-left"><h1>Dashboard</h1><div class="hd-sub">Bangladesh University of Professionals - Institution Overview</div></div></div>
      <div class="stats-row" id="dash-stats">${loading()}</div>`;
    try{
      const s=await Api.getDashboard();
      document.getElementById('dash-stats').innerHTML=[
        ['si-green','tree',s.deptCount,'Departments'],
        ['si-blue','book',s.programCount,'Programs'],
        ['si-amber','grid',s.courseCount,'Courses'],
        ['si-red','users',s.userCount,'Active Users'],
      ].map(([sc,ic,val,lbl])=>`<div class="stat-card"><div class="stat-icon-wrap ${sc}">${ico(ic,18)}</div><div class="stat-val">${val}</div><div class="stat-lbl">${lbl}</div></div>`).join('');
    }catch(e){document.getElementById('dash-stats').innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },

  // ── Structure ──────────────────────────────────────────────
  async structure(){
    document.getElementById('view-root').innerHTML=`
      <div class="page-hd"><div class="page-hd-left"><h1>Institutional Structure</h1><div class="hd-sub">Departments · Programs · Sessions</div></div></div>
      <div id="struct">
        <div class="tab-bar"><button class="tab-btn active" data-tab="td">Departments</button><button class="tab-btn" data-tab="tp">Programs</button><button class="tab-btn" data-tab="ts">Sessions</button></div>
        <div class="tab-pane active" id="td"></div><div class="tab-pane" id="tp"></div><div class="tab-pane" id="ts"></div>
      </div>`;
    initTabs('struct');this._depts();this._progs();this._sessions();
  },

  async _depts(){
    const el=document.getElementById('td');
    el.innerHTML=`<div class="flex-between mb3"><span class="sec-title">Departments</span><button class="btn btn-primary btn-sm" onclick="AdminView._addDept()">${ico('plus')} Add</button></div>
      <div class="tbl-wrap"><table><thead><tr><th>Code</th><th>Name</th><th>Status</th><th class="td-r">Actions</th></tr></thead><tbody id="dtb">${tdLoad(4)}</tbody></table></div>`;
    try{
      const l=await Api.getDepartments();
      document.getElementById('dtb').innerHTML=l.length?l.map(d=>`<tr>
        <td><span class="code-badge">${d.code}</span></td><td class="fw7">${d.name}</td>
        <td><span class="badge ${d.isActive?'bg-green':'bg-gray'}">${d.isActive?'Active':'Inactive'}</span></td>
        <td class="td-r"><button class="btn btn-secondary btn-xs" onclick="AdminView._editDept('${d.id}','${d.name}','${d.code}')">${ico('edit',13)} Edit</button></td>
      </tr>`).join(''):tdEmpty('No departments yet',4);
    }catch(e){document.getElementById('dtb').innerHTML=tdEmpty(e.message,4)}
  },
  _addDept(){showModal('Add Department',`<div class="form-row fr2"><div class="fg"><label>Name</label><input id="md-name" placeholder="e.g. Information and Communication Engineering"></div><div class="fg"><label>Code</label><input id="md-code" placeholder="e.g. ICE" style="text-transform:uppercase"></div></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveDept()">${ico('save')} Save</button>`)},
  async _saveDept(){const name=document.getElementById('md-name').value.trim(),code=document.getElementById('md-code').value.trim();if(!name||!code)return toast('Name and code required','err');
    try{await Api.createDepartment({name,code});toast('Department added');closeModal();this._depts()}catch(e){toast(e.message,'err')}},
  _editDept(id,name,code){showModal('Edit Department',`<div class="form-row fr2"><div class="fg"><label>Name</label><input id="md-name" value="${name}"></div><div class="fg"><label>Code</label><input id="md-code" value="${code}"></div></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._updDept('${id}')">${ico('save')} Save</button>`)},
  async _updDept(id){const name=document.getElementById('md-name').value.trim(),code=document.getElementById('md-code').value.trim();
    try{await Api.updateDepartment(id,{name,code});toast('Updated');closeModal();this._depts()}catch(e){toast(e.message,'err')}},

  async _progs(){
    const el=document.getElementById('tp');
    el.innerHTML=`<div class="flex-between mb3"><span class="sec-title">Programs</span><button class="btn btn-primary btn-sm" onclick="AdminView._addProg()">${ico('plus')} Add</button></div>
      <div class="tbl-wrap"><table><thead><tr><th>Code</th><th>Name</th><th>Department</th></tr></thead><tbody id="ptb">${tdLoad(3)}</tbody></table></div>`;
    try{const l=await Api.getPrograms();document.getElementById('ptb').innerHTML=l.length?l.map(p=>`<tr><td><span class="code-badge">${p.code}</span></td><td class="fw7">${p.name}</td><td class="text-muted">${p.department?.name||'-'}</td></tr>`).join(''):tdEmpty('No programs yet',3)}
    catch(e){document.getElementById('ptb').innerHTML=tdEmpty(e.message,3)}
  },
  async _addProg(){const d=await Api.getDepartments();showModal('Add Program',`<div class="fg mb3"><label>Department</label><select id="mp-dept">${d.map(x=>`<option value="${x.id}">${x.name}</option>`).join('')}</select></div>
    <div class="form-row fr2"><div class="fg"><label>Name</label><input id="mp-name" placeholder="e.g. B.Sc. in ICE"></div><div class="fg"><label>Code</label><input id="mp-code" placeholder="e.g. BICE"></div></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveProg()">${ico('save')} Save</button>`)},
  async _saveProg(){const departmentId=document.getElementById('mp-dept').value,name=document.getElementById('mp-name').value.trim(),code=document.getElementById('mp-code').value.trim();
    if(!name||!code)return toast('Name and code required','err');
    try{await Api.createProgram({departmentId,name,code});toast('Program added');closeModal();this._progs()}catch(e){toast(e.message,'err')}},

  async _sessions(){
    const el=document.getElementById('ts');
    el.innerHTML=`<div class="flex-between mb3"><span class="sec-title">Sessions / Batches</span><button class="btn btn-primary btn-sm" onclick="AdminView._addSession()">${ico('plus')} Add</button></div>
      <div class="tbl-wrap"><table><thead><tr><th>Name</th><th>Start</th><th>Status</th><th class="td-r">Actions</th></tr></thead><tbody id="stb">${tdLoad(4)}</tbody></table></div>`;
    try{
      const l=await Api.getSessions();const sc={ACTIVE:'bg-green',DRAFT:'bg-gray',CLOSED:'bg-amber',ARCHIVED:'bg-gray'};
      document.getElementById('stb').innerHTML=l.length?l.map(s=>`<tr><td class="fw7">${s.name}</td><td class="text-muted">${new Date(s.startDate).getFullYear()}</td>
        <td><span class="badge ${sc[s.status]||'bg-gray'}">${s.status}</span></td>
        <td class="td-r"><button class="btn btn-secondary btn-xs" onclick="AdminView._editSession('${s.id}','${s.name}','${s.status}')">${ico('edit',13)} Status</button></td></tr>`).join(''):tdEmpty('No sessions yet',4);
    }catch(e){document.getElementById('stb').innerHTML=tdEmpty(e.message,4)}
  },
  _addSession(){showModal('Add Session',`<div class="form-row fr2"><div class="fg"><label>Name</label><input id="ms-name" placeholder="e.g. Batch 2026"></div><div class="fg"><label>Start Date</label><input type="date" id="ms-date"></div></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveSession()">${ico('save')} Save</button>`)},
  async _saveSession(){const name=document.getElementById('ms-name').value.trim(),startDate=document.getElementById('ms-date').value;if(!name||!startDate)return toast('Name and date required','err');
    try{await Api.createSession({name,startDate});toast('Session added');closeModal();this._sessions()}catch(e){toast(e.message,'err')}},
  _editSession(id,name,cur){showModal(`Status - ${name}`,`<div class="fg"><label>Status</label><select id="ms-status">${['DRAFT','ACTIVE','CLOSED','ARCHIVED'].map(s=>`<option value="${s}" ${s===cur?'selected':''}>${s}</option>`).join('')}</select></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveSessionStatus('${id}')">${ico('save')} Save</button>`)},
  async _saveSessionStatus(id){const status=document.getElementById('ms-status').value;try{await Api.updateSession(id,{status});toast('Updated');closeModal();this._sessions()}catch(e){toast(e.message,'err')}},

  // ── Courses ────────────────────────────────────────────────
  async courses(){
    document.getElementById('view-root').innerHTML=`
      <div class="page-hd"><div class="page-hd-left"><h1>Courses</h1><div class="hd-sub">All courses across sessions and programs</div></div>
        <div class="page-hd-actions"><button class="btn btn-primary" onclick="AdminView._addCourse()">${ico('plus')} Add Course</button></div>
      </div>
      <div class="filter-bar">
        <div class="search-wrap"><input id="cq" placeholder="Search by code or name…" oninput="AdminView._filterC()"></div>
        <select id="cf-sess" onchange="AdminView._loadC()"><option value="">All Sessions</option></select>
      </div>
      <div class="tbl-wrap"><table><thead><tr><th>Code</th><th>Course Name</th><th>Program</th><th>Batch</th><th style="text-align:center">Cr.</th><th>Faculty</th><th class="td-r" style="min-width:180px">Actions</th></tr></thead>
        <tbody id="ctb">${tdLoad(7)}</tbody></table></div>`;
    const sess=await Api.getSessions();sess.forEach(s=>{const o=document.createElement('option');o.value=s.id;o.textContent=s.name;document.getElementById('cf-sess').appendChild(o)});
    this._loadC();
  },
  async _loadC(){
    const sid=document.getElementById('cf-sess')?.value;document.getElementById('ctb').innerHTML=tdLoad(7);
    try{const l=await Api.getCourses(sid?{sessionId:sid}:{});this._cl=l;this._renderC(l)}catch(e){document.getElementById('ctb').innerHTML=tdEmpty(e.message,7)}
  },
  _filterC(){const q=document.getElementById('cq').value.toLowerCase();this._renderC((this._cl||[]).filter(c=>c.name.toLowerCase().includes(q)||c.code.toLowerCase().includes(q)))},
  _renderC(list){
    document.getElementById('ctb').innerHTML=list.length?list.map(c=>{
      const fac=(c.assignments||[]).map(a=>`<span class="tag">${a.faculty.firstName} ${a.faculty.lastName}</span>`).join(' ')||`<span class="tag tag-warn">⚠ Unassigned</span>`;
      const sn=c.name.replace(/'/g,'&#39;');
      return`<tr>
        <td><span class="code-badge">${c.code}</span></td>
        <td class="fw7">${c.name}</td>
        <td><span class="badge bg-gray">${c.program?.code||'-'}</span></td>
        <td class="text-muted">${c.session?.name||'-'}</td>
        <td style="text-align:center;color:var(--text3)">${c.creditHours}</td>
        <td><div style="display:flex;flex-wrap:wrap;gap:4px">${fac}</div></td>
        <td class="td-r">
          <div style="display:inline-flex;gap:6px">
            <button class="btn btn-secondary btn-xs" onclick="AdminView._assignFac('${c.id}','${c.code}')">${ico('add_user',13)} Assign</button>
            <button class="icon-btn danger" onclick="AdminView._delC('${c.id}','${sn}')" title="Delete course">${ico('trash',13)}</button>
          </div>
        </td></tr>`;
    }).join(''):tdEmpty('No courses found',7);
  },
  async _addCourse(){
    const[p,s]=await Promise.all([Api.getPrograms(),Api.getSessions()]);
    showModal('Add Course',`<div class="form-row fr2 mb3"><div class="fg"><label>Program</label><select id="mco-p">${p.map(x=>`<option value="${x.id}">${x.code} - ${x.name}</option>`).join('')}</select></div>
      <div class="fg"><label>Session / Batch</label><select id="mco-s">${s.map(x=>`<option value="${x.id}">${x.name}</option>`).join('')}</select></div></div>
      <div class="form-row fr2"><div class="fg"><label>Course Name</label><input id="mco-n" placeholder="e.g. Artificial Intelligence"></div>
      <div class="fg"><label>Course Code</label><input id="mco-c" placeholder="e.g. ICE-4107"></div></div>
      <div class="fg mt2" style="max-width:120px"><label>Credit Hours</label><input id="mco-cr" type="number" value="3" min="1" max="6"></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveC()">${ico('save')} Add Course</button>`)},
  async _saveC(){const d={programId:document.getElementById('mco-p').value,sessionId:document.getElementById('mco-s').value,name:document.getElementById('mco-n').value.trim(),code:document.getElementById('mco-c').value.trim(),creditHours:parseInt(document.getElementById('mco-cr').value)||3};
    if(!d.name||!d.code)return toast('Name and code required','err');
    try{await Api.createCourse(d);toast('Course added');closeModal();this._loadC()}catch(e){toast(e.message,'err')}},
  async _delC(id,name){if(!confirm(`Delete "${name}"?`))return;try{await Api.deleteCourse(id);toast('Deleted');this._loadC()}catch(e){toast(e.message,'err')}},
  async _assignFac(courseId,code){
    const users=await Api.getUsers({role:'FACULTY'});
    const c=(this._cl||[]).find(x=>x.id===courseId);
    const assigned=new Set((c?.assignments||[]).map(a=>a.faculty.id));
    showModal(`Assign Faculty - ${code}`,`<div style="display:flex;flex-direction:column;gap:8px;max-height:340px;overflow-y:auto">
      ${users.map(u=>`<label style="display:flex;align-items:center;gap:12px;padding:11px 13px;border:1.5px solid ${assigned.has(u.id)?'var(--green)':'var(--border)'};border-radius:8px;cursor:pointer;background:${assigned.has(u.id)?'var(--green-xl)':'#fff'};transition:all .12s" onmouseenter="this.style.borderColor='var(--green)'" onmouseleave="this.style.borderColor='${assigned.has(u.id)?'var(--green)':'var(--border)'}'"">
        <input type="checkbox" value="${u.id}" ${assigned.has(u.id)?'checked':''} style="width:auto;accent-color:var(--green)">
        <div><div class="fw7">${u.firstName} ${u.lastName}</div><div class="text-sm text-muted">${u.email}</div></div>
      </label>`).join('')}</div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveAssign('${courseId}')">${ico('save')} Save</button>`)},
  async _saveAssign(courseId){const ids=[...document.querySelectorAll('#modal-body input[type=checkbox]:checked')].map(c=>c.value);
    try{await Api.assignFaculty(courseId,ids);toast('Faculty assigned');closeModal();this._loadC()}catch(e){toast(e.message,'err')}},

  // ── Users ──────────────────────────────────────────────────
  async users(){
    const [sessions,depts]=await Promise.all([Api.getSessions(),Api.getDepartments()]).catch(()=>[[],[]]);
    document.getElementById('view-root').innerHTML=`
      <div class="page-hd"><div class="page-hd-left"><h1>Users</h1><div class="hd-sub">Search by role, batch or department to view users</div></div>
        <div class="page-hd-actions"><button class="btn btn-primary" onclick="AdminView._addUser()">${ico('add_user')} Add User</button></div></div>
      <div class="filter-bar">
        <div class="search-wrap"><input id="uq" placeholder="Search name or email..." oninput="AdminView._filterU()"></div>
        <select id="uf-role" onchange="AdminView._loadU()">
          <option value="">-- Select Role --</option>
          <option value="ADMIN">Admin</option>
          <option value="FACULTY">Faculty</option>
          <option value="STUDENT">Student</option>
        </select>
        <select id="uf-sess" onchange="AdminView._loadU()">
          <option value="">-- Select Batch --</option>
          ${sessions.map(s=>`<option value="${s.id}">${s.name}</option>`).join('')}
        </select>
        <select id="uf-dept" onchange="AdminView._loadU()">
          <option value="">-- Select Dept --</option>
          ${depts.map(d=>`<option value="${d.id}">${d.name}</option>`).join('')}
        </select>
      </div>
      <div class="tbl-wrap"><table><thead><tr>
        <th>Name</th><th>Email</th><th>Role</th><th>ID</th>
        <th style="text-align:center">Active</th><th>Last Login</th>
      </tr></thead>
      <tbody id="utb"><tr><td colspan="6" class="td-load text-muted">Select a filter above to view users.</td></tr></tbody>
      </table></div>`;
  },
  async _loadU(){
    const role=document.getElementById('uf-role')?.value;
    const sessId=document.getElementById('uf-sess')?.value;
    const deptId=document.getElementById('uf-dept')?.value;
    // Require at least one filter to be selected
    if(!role && !sessId && !deptId){
      document.getElementById('utb').innerHTML='<tr><td colspan="6" class="td-load text-muted">Select a filter above to view users.</td></tr>';
      return;
    }
    document.getElementById('utb').innerHTML=tdLoad(6);
    try{
      const params={};
      if(role) params.role=role;
      if(sessId) params.sessionId=sessId;
      const l=await Api.getUsers(params);
      this._ul=l;
      if(!l.length){
        document.getElementById('utb').innerHTML='<tr><td colspan="6" class="td-load text-muted">No users found for the selected filters.</td></tr>';
      } else {
        this._renderU(l);
      }
    }catch(e){document.getElementById('utb').innerHTML=tdEmpty(e.message,6)}
  },
  _filterU(){const q=document.getElementById('uq').value.toLowerCase();this._renderU((this._ul||[]).filter(u=>`${u.firstName} ${u.lastName} ${u.email}`.toLowerCase().includes(q)))},
  _renderU(list){
    document.getElementById('utb').innerHTML=list.length?list.map(u=>`<tr>
      <td class="fw7">${u.firstName} ${u.lastName}</td>
      <td class="text-muted text-sm">${u.email}</td>
      <td><span class="role-pill rp-${u.role}">${u.role}</span></td>
      <td class="text-mono text-sm text-muted">${u.institutionalId||'-'}</td>
      <td style="text-align:center">
        <label class="tog"><input type="checkbox" ${u.isActive?'checked':''} onchange="AdminView._togUser('${u.id}',this)"><span class="tog-track"></span></label>
      </td>
      <td class="text-muted text-sm">${u.lastLoginAt?new Date(u.lastLoginAt).toLocaleDateString():'Never'}</td>
    </tr>`).join(''):tdEmpty('No users found',6)},
  async _togUser(id,cb){const v=cb.checked;try{await Api.updateUser(id,{isActive:v});toast(`User ${v?'activated':'deactivated'}`)}catch(e){cb.checked=!v;toast(e.message,'err')}},
  _addUser(){showModal('Create User',`<div class="form-row fr2 mb3"><div class="fg"><label>First Name</label><input id="mu-fn" placeholder="First name"></div><div class="fg"><label>Last Name</label><input id="mu-ln" placeholder="Last name"></div></div>
    <div class="fg mb3"><label>Email</label><input id="mu-em" type="email" placeholder="name@bup.edu.bd"></div>
    <div class="form-row fr2"><div class="fg"><label>Role</label><select id="mu-role"><option value="STUDENT">Student</option><option value="FACULTY">Faculty</option><option value="ADMIN">Admin</option></select></div>
    <div class="fg"><label>Institutional ID <span class="text-muted">(optional)</span></label><input id="mu-id" placeholder="e.g. 2022-ICE-001"></div></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._saveUser()">${ico('save')} Create</button>`)},
  async _saveUser(){const d={firstName:document.getElementById('mu-fn').value.trim(),lastName:document.getElementById('mu-ln').value.trim(),email:document.getElementById('mu-em').value.trim(),role:document.getElementById('mu-role').value,institutionalId:document.getElementById('mu-id').value.trim()||null};
    if(!d.firstName||!d.lastName||!d.email)return toast('Name and email required','err');
    try{const r=await Api.createUser(d);toast(`Created! Temp password: ${r.tempPassword}`,'ok');closeModal();this._loadU()}catch(e){toast(e.message,'err')}},

  // ── Outcomes ───────────────────────────────────────────────
  async outcomes(){
    const progs=await Api.getPrograms();
    document.getElementById('view-root').innerHTML=`
      <div class="page-hd"><div class="page-hd-left"><h1>Program Outcomes</h1><div class="hd-sub">PO1-PO12 per program</div></div>
        <div class="page-hd-actions">
          <select id="po-prog" style="min-width:260px" onchange="AdminView._loadPOs()">${progs.map(p=>`<option value="${p.id}">${p.code} - ${p.name}</option>`).join('')}</select>
          <button class="btn btn-primary" onclick="AdminView._addPO()">${ico('plus')} Add PO</button>
        </div>
      </div>
      <div id="po-area">${loading()}</div>`;
    if(progs.length)this._loadPOs();
  },
  async _loadPOs(){
    const pid=document.getElementById('po-prog')?.value;if(!pid)return;
    const el=document.getElementById('po-area');el.innerHTML=loading();
    try{
      const l=await Api.getProgramOutcomes(pid);
      el.innerHTML=l.length?`<div class="po-grid">${l.map(po=>`<div class="po-card">
        <div class="po-card-top"><span class="po-code">${po.code}</span>
          <div style="display:flex;gap:6px">
            <button class="btn btn-secondary btn-xs" onclick="AdminView._editPO('${po.id}','${po.code}','${po.title.replace(/'/g,'&#39;')}','${(po.description||'').replace(/'/g,'&#39;')}')">${ico('edit',13)} Edit</button>
            <button class="icon-btn danger" onclick="AdminView._delPO('${po.id}','${po.code}')">${ico('trash',13)}</button>
          </div>
        </div>
        <div class="po-card-title">${po.title}</div>
        ${po.description?`<div class="po-card-desc">${po.description}</div>`:''}
      </div>`).join('')}</div>`
      :`<div class="empty-box"><div class="empty-ico">${ico('target',24)}</div><h3>No outcomes yet</h3><p>Add PO1-PO12 for this program.</p></div>`;
    }catch(e){el.innerHTML=`<div class="alert alert-error"><span class="alert-icon">⚠</span>${e.message}</div>`}
  },
  _addPO(){if(!document.getElementById('po-prog')?.value)return toast('Select a program first','err');
    showModal('Add Program Outcome',`<div class="form-row fr2 mb3"><div class="fg"><label>Code</label><input id="mpo-code" placeholder="e.g. PO1"></div><div class="fg"><label>Title</label><input id="mpo-title" placeholder="e.g. Engineering Knowledge"></div></div>
      <div class="fg"><label>Description</label><textarea id="mpo-desc" rows="3" placeholder="Describe this outcome…"></textarea></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._savePO()">${ico('save')} Add</button>`)},
  async _savePO(){const pid=document.getElementById('po-prog').value,code=document.getElementById('mpo-code').value.trim(),title=document.getElementById('mpo-title').value.trim(),description=document.getElementById('mpo-desc').value.trim();
    if(!code||!title)return toast('Code and title required','err');
    try{await Api.createProgramOutcome(pid,{code,title,description});toast('PO added');closeModal();this._loadPOs()}catch(e){toast(e.message,'err')}},
  _editPO(id,code,title,desc){showModal('Edit PO',`<div class="form-row fr2 mb3"><div class="fg"><label>Code</label><input id="mpo-code" value="${code}"></div><div class="fg"><label>Title</label><input id="mpo-title" value="${title}"></div></div>
    <div class="fg"><label>Description</label><textarea id="mpo-desc" rows="3">${desc}</textarea></div>`,
    `<button class="btn btn-ghost" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="AdminView._updPO('${id}')">${ico('save')} Save</button>`)},
  async _updPO(id){const code=document.getElementById('mpo-code').value.trim(),title=document.getElementById('mpo-title').value.trim(),description=document.getElementById('mpo-desc').value.trim();
    try{await Api.updateProgramOutcome(id,{code,title,description});toast('Updated');closeModal();this._loadPOs()}catch(e){toast(e.message,'err')}},
  async _delPO(id,code){if(!confirm(`Delete ${code}? Fails if mappings exist.`))return;
    try{await Api.deleteProgramOutcome(id);toast('Deleted');this._loadPOs()}catch(e){toast(e.message,'err')}},

  // ── Thresholds ─────────────────────────────────────────────
  async attainmentReport(){
    document.getElementById('view-root').innerHTML=`<div class="page-hd"><div class="page-hd-left"><h1>Attainment Report</h1><div class="hd-sub">CO/PO attainment by batch and department</div></div></div>${loading()}`;
    try{
      const [sessions,depts]=await Promise.all([Api.getSessions(),Api.getDepartments()]);
      document.getElementById('view-root').innerHTML=`
        <div class="page-hd"><div class="page-hd-left"><h1>Attainment Report</h1><div class="hd-sub">View attainment across batches and departments</div></div></div>
        <div class="card mb4"><div class="card-bd">
          <div class="filter-bar" style="margin-bottom:0">
            <div class="fg" style="flex:1;margin:0"><label>Batch / Session</label>
              <select id="ar-sess"><option value="">All Batches</option>${sessions.map(s=>`<option value="${s.id}">${s.name}</option>`).join('')}</select></div>
            <div class="fg" style="flex:1;margin:0"><label>Department</label>
              <select id="ar-dept"><option value="">All Departments</option>${depts.map(d=>`<option value="${d.id}">${d.name}</option>`).join('')}</select></div>
            <div style="padding-top:22px">
              <button class="btn btn-primary" onclick="AdminView._loadAttainReport()">${ico('chart')} View Report</button>
            </div>
          </div>
        </div></div>
        <div id="ar-result"></div>`;
    }catch(e){document.getElementById('view-root').innerHTML+=`<div class="alert alert-error"><span class="alert-icon">&#9888;</span>${e.message}</div>`}
  },

  async _loadAttainReport(){
    const sessId=document.getElementById('ar-sess').value;
    const deptId=document.getElementById('ar-dept').value;
    const el=document.getElementById('ar-result');
    el.innerHTML=loading();
    try{
      const filters={};
      if(sessId) filters.sessionId=sessId;
      if(deptId) filters.departmentId=deptId;
      const{coSummary,poSummary}=await Api.getAttainmentReport(filters);
      if(!coSummary.length&&!poSummary.length){
        el.innerHTML=`<div class="empty-box"><div class="empty-ico">${ico('chart',24)}</div><h3>No data for this filter</h3><p>Try a different batch or department.</p></div>`;
        return;
      }
      el.innerHTML=`
        <div class="flex-between mb3"><div class="sec-title">Course Outcome Attainment</div>
          <button class="btn btn-secondary btn-sm" onclick="AdminView._exportCSV()">${ico('dl',13)} Export CSV</button></div>
        <div class="tbl-wrap mb4"><table>
          <thead><tr><th>Course</th><th>CO</th><th>Title</th>
            <th style="text-align:center">Attained</th><th style="text-align:center">Total</th>
            <th style="min-width:160px">Rate</th></tr></thead>
          <tbody>${coSummary.map(r=>{const lvl=r.attainmentRate>=60?'L3':'L0';return`<tr>
            <td><span class="code-badge">${r.courseCode}</span></td>
            <td><span class="badge bg-green">${r.coCode}</span></td>
            <td>${r.coTitle}</td>
            <td style="text-align:center;font-weight:700;color:var(--l3)">${r.attainedCount}</td>
            <td style="text-align:center;color:var(--text3)">${r.total}</td>
            <td>${attBar(r.attainmentRate,lvl)}</td>
          </tr>`}).join('')}</tbody>
        </table></div>
        <div class="sec-title mb3">Program Outcome Attainment</div>
        <div class="tbl-wrap"><table>
          <thead><tr><th>PO</th><th>Title</th>
            <th style="text-align:center">Attained</th><th style="text-align:center">Total</th>
            <th style="min-width:160px">Rate</th></tr></thead>
          <tbody>${poSummary.map(r=>{const lvl=r.attainmentRate>=60?'L3':'L0';return`<tr>
            <td><span class="badge bg-blue">${r.poCode}</span></td>
            <td>${r.poTitle}</td>
            <td style="text-align:center;font-weight:700;color:var(--l3)">${r.attainedCount}</td>
            <td style="text-align:center;color:var(--text3)">${r.total}</td>
            <td>${attBar(r.attainmentRate,lvl)}</td>
          </tr>`}).join('')}</tbody>
        </table></div>`;
      this._lastReport={coSummary,poSummary};
    }catch(e){el.innerHTML=`<div class="alert alert-error"><span class="alert-icon">&#9888;</span>${e.message}</div>`}
  },

  _exportCSV(){
    const d=this._lastReport; if(!d) return;
    const rows=[
      ['Type','Course','Code','Title','Attained','Total','Rate(%)'],
      ...d.coSummary.map(r=>['CO',r.courseCode,r.coCode,r.coTitle,r.attainedCount,r.total,r.attainmentRate]),
      ['','','','','','',''],
      ...d.poSummary.map(r=>['PO','',r.poCode,r.poTitle,r.attainedCount,r.total,r.attainmentRate]),
    ];
    const csv=rows.map(r=>r.map(v=>'"'+String(v||'').replace(/"/g,'""')+'"').join(',')).join('\n');
    const a=document.createElement('a');
    a.href=URL.createObjectURL(new Blob([csv],{type:'text/csv'}));
    a.download='attainment_report.csv'; a.click();
  },

};
