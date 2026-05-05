/* MedCare CRM — 4 screens */
const { useState } = React;
const C = window.MC_C;
const FONT = window.MC_FONT;
const Icon = window.MC_Icon;
const ICONS = window.MC_ICONS;

/* ─── BOTTOM NAV ─── */
const BottomNav = ({ active = 'home', onNavigate }) => {
  const tabs = [
    { id: 'home', icon: ICONS.home, label: 'Головна' },
    { id: 'appointments', icon: ICONS.calendar, label: 'Прийоми' },
    { id: 'patients', icon: ICONS.users, label: 'Пацієнти' },
    { id: 'reports', icon: ICONS.chart, label: 'Звіти' },
  ];
  return (
    <div style={{ display: 'flex', background: C.white, borderTop: `1px solid ${C.border}`, padding: '8px 0 4px' }}>
      {tabs.map(t => {
        const a = active === t.id;
        return (
          <div key={t.id} onClick={() => onNavigate && onNavigate(t.id === 'home' ? 'dashboard' : t.id === 'patients' ? 'patient' : t.id === 'appointments' ? 'appointment' : 'dashboard')} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, cursor: 'pointer', padding: '6px 0' }}>
            <Icon d={t.icon} size={22} color={a ? C.primary : '#9CA3AF'} />
            <span style={{ fontSize: 10, fontWeight: a ? 700 : 500, color: a ? C.primary : '#9CA3AF' }}>{t.label}</span>
          </div>
        );
      })}
    </div>
  );
};

/* ═══════════════════════════════════════
   1. LOGIN SCREEN
   ═══════════════════════════════════════ */
const LoginScreen = ({ onLogin }) => {
  const [email, setEmail] = useState('admin@medcare.ua');
  const [pass, setPass] = useState('••••••••');
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: `linear-gradient(180deg, ${C.primary} 0%, ${C.primaryDark} 100%)`, fontFamily: FONT }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 28px' }}>
        {/* Logo */}
        <div style={{ width: 76, height: 76, borderRadius: 22, background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16, backdropFilter: 'blur(10px)' }}>
          <svg width="40" height="40" viewBox="0 0 24 24" fill="white"><path d="M19 3H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2V5a2 2 0 00-2-2zm-2 10h-4v4h-2v-4H7v-2h4V7h2v4h4v2z" /></svg>
        </div>
        <div style={{ color: '#fff', fontSize: 24, fontWeight: 800, letterSpacing: 0.3 }}>MedCare CRM</div>
        <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13, marginBottom: 36, marginTop: 4 }}>Система управління лікарнею</div>

        <div style={{ width: '100%' }}>
          <label style={{ color: 'rgba(255,255,255,0.85)', fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>Електронна пошта</label>
          <input value={email} onChange={e => setEmail(e.target.value)} style={{ width: '100%', padding: '13px 16px', borderRadius: 12, border: '1px solid rgba(255,255,255,0.25)', background: 'rgba(255,255,255,0.12)', color: '#fff', fontSize: 14, fontFamily: FONT, outline: 'none', marginBottom: 18 }} />

          <label style={{ color: 'rgba(255,255,255,0.85)', fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>Пароль</label>
          <input type="password" value={pass} onChange={e => setPass(e.target.value)} style={{ width: '100%', padding: '13px 16px', borderRadius: 12, border: '1px solid rgba(255,255,255,0.25)', background: 'rgba(255,255,255,0.12)', color: '#fff', fontSize: 14, fontFamily: FONT, outline: 'none', marginBottom: 24 }} />

          <button onClick={onLogin} style={{ width: '100%', padding: '15px', borderRadius: 14, border: 'none', background: '#fff', color: C.primary, fontSize: 16, fontWeight: 700, fontFamily: FONT, cursor: 'pointer', boxShadow: '0 8px 24px rgba(0,0,0,0.15)' }}>
            Увійти до системи
          </button>

          <div style={{ textAlign: 'center', marginTop: 16, color: 'rgba(255,255,255,0.7)', fontSize: 13, cursor: 'pointer' }}>Забули пароль?</div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '22px 0' }}>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.2)' }} />
            <span style={{ color: 'rgba(255,255,255,0.5)', fontSize: 12 }}>або</span>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,255,255,0.2)' }} />
          </div>

          <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.75)', fontSize: 13 }}>Вхід через картку співробітника 💳</div>
        </div>
      </div>
    </div>
  );
};

/* ═══════════════════════════════════════
   2. DASHBOARD SCREEN
   ═══════════════════════════════════════ */
const DashboardScreen = ({ onNavigate, onLogout }) => {
  const stats = [
    { v: '12', l: 'Прийомів сьогодні' },
    { v: '3', l: 'Нових пацієнтів' },
    { v: '248', l: 'Активних пацієнтів' },
    { v: '98%', l: 'Заповненість' },
  ];
  const actions = [
    { i: ICONS.user, l: 'Новий\nпацієнт', c: '#E3F2FD', go: 'patient' },
    { i: ICONS.calendar, l: 'Запис', c: '#FFF3E0', go: 'appointment' },
    { i: ICONS.pill, l: 'Рецепт', c: '#FCE4EC' },
    { i: ICONS.file, l: 'Картка', c: '#E8F5E9', go: 'patient' },
  ];
  const appts = [
    { name: 'Петренко Олексій', spec: 'Кардіологія • Повторний', time: '09:00', a: '👨' },
    { name: 'Коваль Марина', spec: 'Загальна практика • Первинний', time: '09:30', a: '👩' },
    { name: 'Бойко Степан', spec: 'Неврологія • Консультація', time: '10:00', a: '👴' },
  ];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: C.bg, fontFamily: FONT }}>
      {/* Header */}
      <div style={{ background: `linear-gradient(135deg, ${C.primary}, ${C.primaryDark})`, padding: '20px 20px 22px', borderRadius: '0 0 24px 24px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 13 }}>Доброго ранку, 👋</div>
            <div style={{ color: '#fff', fontSize: 20, fontWeight: 800, marginTop: 2 }}>Д-р Іваненко Олена</div>
          </div>
          <div onClick={onLogout} style={{ width: 36, height: 36, borderRadius: 12, background: 'rgba(255,255,255,0.18)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <Icon d={ICONS.bell} size={18} color="#fff" />
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 18 }}>
          {stats.map((s, i) => (
            <div key={i} style={{ background: 'rgba(255,255,255,0.15)', borderRadius: 12, padding: '12px 14px' }}>
              <div style={{ color: '#fff', fontSize: 22, fontWeight: 800 }}>{s.v}</div>
              <div style={{ color: 'rgba(255,255,255,0.75)', fontSize: 11, marginTop: 2 }}>{s.l}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Quick actions */}
      <div style={{ display: 'flex', justifyContent: 'space-around', padding: '18px 16px 6px' }}>
        {actions.map((a, i) => (
          <div key={i} onClick={() => a.go && onNavigate(a.go)} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, cursor: 'pointer', flex: 1 }}>
            <div style={{ width: 50, height: 50, borderRadius: 16, background: a.c, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon d={a.i} size={22} color={C.primary} />
            </div>
            <div style={{ fontSize: 11, color: C.textSec, textAlign: 'center', whiteSpace: 'pre-line', lineHeight: 1.2, fontWeight: 600 }}>{a.l}</div>
          </div>
        ))}
      </div>

      {/* Appointments */}
      <div style={{ flex: 1, padding: '14px 16px 0', overflow: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
          <div style={{ fontSize: 16, fontWeight: 700, color: C.text }}>Найближчі прийоми</div>
          <div style={{ fontSize: 12, color: C.primary, fontWeight: 600, cursor: 'pointer' }}>Усі →</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {appts.map((a, i) => (
            <div key={i} onClick={() => onNavigate('patient')} style={{ background: C.card, borderRadius: 14, padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
              <div style={{ width: 44, height: 44, borderRadius: 14, background: '#E3F2FD', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22 }}>{a.a}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: C.text }}>{a.name}</div>
                <div style={{ fontSize: 11, color: C.textSec, marginTop: 2 }}>{a.spec}</div>
              </div>
              <div style={{ background: '#E3F2FD', color: C.primary, fontSize: 13, fontWeight: 700, padding: '6px 12px', borderRadius: 10 }}>{a.time}</div>
            </div>
          ))}
        </div>
      </div>

      <BottomNav active="home" onNavigate={onNavigate} />
    </div>
  );
};

/* ═══════════════════════════════════════
   3. PATIENT CARD SCREEN
   ═══════════════════════════════════════ */
const PatientScreen = ({ onBack, onNavigate }) => {
  const [tab, setTab] = useState('card');
  const tags = ['II гр. крові', 'Rh+', 'Гіпертонія'];
  const vitals = [
    { v: '145/90', u: 'мм рт.ст.', l: 'Тиск', c: C.danger },
    { v: '78', u: 'уд/хв', l: 'Пульс', c: C.success },
    { v: '82', u: 'кг', l: 'Вага', c: C.primary },
    { v: '36.6', u: '°C', l: 'Температура', c: C.warning },
  ];
  const subTabs = [
    { id: 'card', l: 'Картка' },
    { id: 'visits', l: 'Прийоми' },
    { id: 'rx', l: 'Рецепти' },
    { id: 'labs', l: 'Аналізи' },
  ];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: C.bg, fontFamily: FONT }}>
      {/* Header */}
      <div style={{ background: `linear-gradient(135deg, ${C.primary}, ${C.primaryDark})`, padding: '14px 20px 18px' }}>
        <div onClick={onBack} style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#fff', fontSize: 14, fontWeight: 600, cursor: 'pointer', marginBottom: 14 }}>
          <Icon d={ICONS.back} size={18} color="#fff" /> Картка пацієнта
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 56, height: 56, borderRadius: 18, background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28 }}>👨</div>
          <div style={{ flex: 1 }}>
            <div style={{ color: '#fff', fontSize: 16, fontWeight: 800 }}>Петренко Олексій Іванович</div>
            <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 11, marginTop: 2 }}>ID: #PT-00482 • 15.03.1978 (47 р.)</div>
            <div style={{ display: 'flex', gap: 5, marginTop: 6, flexWrap: 'wrap' }}>
              {tags.map((t, i) => (
                <span key={i} style={{ background: i === 2 ? 'rgba(239,68,68,0.4)' : 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 10, fontWeight: 700, padding: '3px 8px', borderRadius: 6 }}>{t}</span>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Sub-tabs */}
      <div style={{ display: 'flex', background: '#fff', borderBottom: `1px solid ${C.border}`, padding: '0 8px' }}>
        {subTabs.map(t => {
          const active = t.id === tab;
          return (
            <div key={t.id} onClick={() => setTab(t.id)} style={{ flex: 1, textAlign: 'center', padding: '12px 0', cursor: 'pointer', fontSize: 13, fontWeight: active ? 700 : 500, color: active ? C.primary : C.textSec, borderBottom: active ? `2px solid ${C.primary}` : '2px solid transparent' }}>
              {t.l}
            </div>
          );
        })}
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px' }}>
        {/* Personal data */}
        <div style={{ background: C.card, borderRadius: 16, padding: 16, marginBottom: 12, boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ fontSize: 12, fontWeight: 800, color: C.text, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 12 }}>Особисті дані</div>
          {[
            ['Страховий поліс', 'UA-2024-8847261'],
            ['Телефон', '+380 67 123 45 67'],
            ['Лікар', 'Іваненко О.В.'],
            ['Алергії', 'Пеніцилін', true],
          ].map(([k, v, danger], i, arr) => (
            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: i < arr.length - 1 ? `1px solid ${C.border}` : 'none' }}>
              <span style={{ fontSize: 13, color: C.textSec }}>{k}</span>
              <span style={{ fontSize: 13, fontWeight: 600, color: danger ? C.danger : C.text }}>{v}</span>
            </div>
          ))}
        </div>

        {/* Vitals */}
        <div style={{ background: C.card, borderRadius: 16, padding: 16, marginBottom: 12, boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ fontSize: 12, fontWeight: 800, color: C.text, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 12 }}>Показники здоров'я</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {vitals.map((v, i) => (
              <div key={i} style={{ background: C.bg, borderRadius: 12, padding: 12, borderLeft: `3px solid ${v.c}` }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                  <div style={{ fontSize: 20, fontWeight: 800, color: C.text }}>{v.v}</div>
                  <div style={{ fontSize: 10, color: C.textSec }}>{v.u}</div>
                </div>
                <div style={{ fontSize: 11, color: C.textSec, marginTop: 2, fontWeight: 600 }}>{v.l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Action button */}
        <button onClick={() => onNavigate('appointment')} style={{ width: '100%', padding: '14px', borderRadius: 14, border: 'none', background: C.primary, color: '#fff', fontSize: 15, fontWeight: 700, fontFamily: FONT, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 8 }}>
          <Icon d={ICONS.plus} size={18} color="#fff" /> Записати на прийом
        </button>
      </div>

      <BottomNav active="patients" onNavigate={onNavigate} />
    </div>
  );
};

/* ═══════════════════════════════════════
   4. APPOINTMENT SCREEN
   ═══════════════════════════════════════ */
const AppointmentScreen = ({ onBack, onNavigate }) => {
  const [selDate, setSelDate] = useState(7);
  const [selTime, setSelTime] = useState('09:00');
  const [doctor, setDoctor] = useState('Іваненко О.В.');

  const days = [
    [28, 29, 30, 1, 2, 3, 4],
    [5, 6, 7, 8, 9, 10, 11],
    [12, 13, 14, 15, 16, 17, 18],
    [19, 20, 21, 22, 23, 24, 25],
  ];
  const isPrevMonth = d => days[0].slice(0, 3).includes(d);
  const slots = [
    { t: '08:00', busy: true },
    { t: '08:30' },
    { t: '09:00' },
    { t: '09:30' },
    { t: '10:00', busy: true },
    { t: '10:30' },
    { t: '11:00' },
    { t: '11:30', busy: true },
    { t: '14:00' },
    { t: '14:30' },
    { t: '15:00' },
    { t: '15:30' },
  ];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: C.bg, fontFamily: FONT }}>
      {/* Header */}
      <div style={{ background: `linear-gradient(135deg, ${C.primary}, ${C.primaryDark})`, padding: '14px 20px 18px' }}>
        <div onClick={onBack} style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#fff', fontSize: 14, fontWeight: 600, cursor: 'pointer', marginBottom: 12 }}>
          <Icon d={ICONS.back} size={18} color="#fff" /> Запис на прийом
        </div>
        <div style={{ color: '#fff', fontSize: 18, fontWeight: 800 }}>Оберіть час візиту</div>
        <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12, marginTop: 2 }}>Петренко О.І. → {doctor}</div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '14px 16px' }}>
        {/* Doctor */}
        <div style={{ background: C.card, borderRadius: 14, padding: '12px 14px', marginBottom: 12, display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ width: 40, height: 40, borderRadius: 12, background: '#E8F5E9', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20 }}>👩‍⚕️</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: C.text }}>Д-р Іваненко О.В.</div>
            <div style={{ fontSize: 11, color: C.textSec }}>Кардіолог • кабінет 305</div>
          </div>
          <div style={{ fontSize: 12, color: C.primary, fontWeight: 600 }}>Змінити</div>
        </div>

        {/* Calendar */}
        <div style={{ background: C.card, borderRadius: 16, padding: 14, marginBottom: 12, boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ fontSize: 14, fontWeight: 700, color: C.text }}>Грудень 2026</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: C.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: C.textSec, fontSize: 14 }}>‹</div>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: C.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: C.textSec, fontSize: 14 }}>›</div>
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 4, marginBottom: 6 }}>
            {['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'].map(d => (
              <div key={d} style={{ textAlign: 'center', fontSize: 11, fontWeight: 700, color: C.textSec, padding: '4px 0' }}>{d}</div>
            ))}
          </div>
          {days.map((row, ri) => (
            <div key={ri} style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 4, marginBottom: 4 }}>
              {row.map((d, di) => {
                const prev = ri === 0 && di < 3;
                const sel = !prev && d === selDate;
                return (
                  <div key={di} onClick={() => !prev && setSelDate(d)} style={{ aspectRatio: '1/1', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: sel ? 800 : 600, color: prev ? '#D1D5DB' : (sel ? '#fff' : C.text), background: sel ? C.primary : 'transparent', cursor: prev ? 'default' : 'pointer' }}>
                    {d}
                  </div>
                );
              })}
            </div>
          ))}
        </div>

        {/* Time slots */}
        <div style={{ background: C.card, borderRadius: 16, padding: 14, marginBottom: 12, boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ fontSize: 13, fontWeight: 800, color: C.text, marginBottom: 10, textTransform: 'uppercase', letterSpacing: 0.5 }}>Доступні слоти • 7 грудня</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 8 }}>
            {slots.map((s, i) => {
              const sel = s.t === selTime && !s.busy;
              return (
                <div key={i} onClick={() => !s.busy && setSelTime(s.t)} style={{ padding: '10px 0', borderRadius: 10, textAlign: 'center', fontSize: 13, fontWeight: 700, background: s.busy ? '#F3F4F6' : (sel ? C.primary : '#E3F2FD'), color: s.busy ? '#9CA3AF' : (sel ? '#fff' : C.primary), cursor: s.busy ? 'not-allowed' : 'pointer', textDecoration: s.busy ? 'line-through' : 'none' }}>
                  {s.t}
                </div>
              );
            })}
          </div>
        </div>

        {/* Reason */}
        <div style={{ background: C.card, borderRadius: 16, padding: 14, marginBottom: 12, boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ fontSize: 13, fontWeight: 800, color: C.text, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.5 }}>Причина візиту</div>
          <select defaultValue="repeat" style={{ width: '100%', padding: '12px 14px', borderRadius: 10, border: `1px solid ${C.border}`, background: C.bg, fontSize: 13, fontFamily: FONT, color: C.text, outline: 'none' }}>
            <option value="repeat">Повторний прийом</option>
            <option>Первинна консультація</option>
            <option>Профілактичний огляд</option>
            <option>Невідкладна допомога</option>
          </select>
        </div>
      </div>

      {/* Confirm */}
      <div style={{ padding: '12px 16px', background: C.white, borderTop: `1px solid ${C.border}` }}>
        <button onClick={() => { alert('Запис підтверджено!\n7 грудня • ' + selTime); onNavigate('dashboard'); }} style={{ width: '100%', padding: '15px', borderRadius: 14, border: 'none', background: C.primary, color: '#fff', fontSize: 15, fontWeight: 700, fontFamily: FONT, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <Icon d={ICONS.check} size={18} color="#fff" /> Підтвердити запис на {selTime}
        </button>
      </div>
    </div>
  );
};

window.MC_LoginScreen = LoginScreen;
window.MC_DashboardScreen = DashboardScreen;
window.MC_PatientScreen = PatientScreen;
window.MC_AppointmentScreen = AppointmentScreen;
