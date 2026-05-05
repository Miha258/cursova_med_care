/* MedCare CRM — main app shell with iOS frame + design canvas */
const { useState } = React;

const C = window.MC_C;
const FONT = window.MC_FONT;

const PHONE_W = 390;
const PHONE_H = 844;

/* Single phone screen wrapped in iOS frame */
const Phone = ({ children, label, time = '9:41' }) => (
  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
    <window.IOSDevice width={PHONE_W} height={PHONE_H} dark={true}>
      <div style={{ width: '100%', height: '100%', overflow: 'hidden', background: '#F5F7FA' }}>
        {children}
      </div>
    </window.IOSDevice>
    <div style={{ color: '#fff', fontSize: 14, fontWeight: 600, fontFamily: FONT, letterSpacing: 0.3, opacity: 0.85 }}>{label}</div>
  </div>
);

/* Interactive prototype: navigates between screens within a single phone */
const InteractivePhone = () => {
  const [screen, setScreen] = useState('login');
  const navigate = (s) => setScreen(s);
  const logout = () => setScreen('login');

  let content = null;
  if (screen === 'login') content = <window.MC_LoginScreen onLogin={() => setScreen('dashboard')} />;
  else if (screen === 'dashboard') content = <window.MC_DashboardScreen onNavigate={navigate} onLogout={logout} />;
  else if (screen === 'patient') content = <window.MC_PatientScreen onBack={() => setScreen('dashboard')} onNavigate={navigate} />;
  else if (screen === 'appointment') content = <window.MC_AppointmentScreen onBack={() => setScreen('dashboard')} onNavigate={navigate} />;

  return <Phone label="Інтерактивний прототип →" time="9:41">{content}</Phone>;
};

const App = () => {
  return (
    <div style={{ minHeight: '100vh', background: '#0F172A', padding: '40px 24px', fontFamily: FONT }}>
      {/* Title */}
      <div style={{ textAlign: 'center', marginBottom: 36, color: '#fff' }}>
        <div style={{ fontSize: 13, opacity: 0.5, letterSpacing: 2, textTransform: 'uppercase', marginBottom: 8 }}>Курсова робота • Flutter UI</div>
        <div style={{ fontSize: 36, fontWeight: 800, letterSpacing: 0.5 }}>MedCare CRM</div>
        <div style={{ fontSize: 14, opacity: 0.6, marginTop: 6 }}>Макет мобільного клієнта на Dart/Flutter • Material Design 3</div>
      </div>

      {/* Static row of all 4 screens */}
      <div style={{ display: 'flex', gap: 28, justifyContent: 'center', flexWrap: 'wrap', marginBottom: 50 }}>
        <Phone label="Рис. 2.3а — Авторизація" time="9:41">
          <window.MC_LoginScreen onLogin={() => {}} />
        </Phone>
        <Phone label="Рис. 2.3б — Головний екран" time="9:41">
          <window.MC_DashboardScreen onNavigate={() => {}} onLogout={() => {}} />
        </Phone>
        <Phone label="Рис. 2.4а — Картка пацієнта" time="9:41">
          <window.MC_PatientScreen onBack={() => {}} onNavigate={() => {}} />
        </Phone>
        <Phone label="Рис. 2.4б — Запис на прийом" time="9:41">
          <window.MC_AppointmentScreen onBack={() => {}} onNavigate={() => {}} />
        </Phone>
      </div>

      {/* Interactive */}
      <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: 36 }}>
        <div style={{ textAlign: 'center', marginBottom: 24, color: '#fff' }}>
          <div style={{ fontSize: 13, opacity: 0.5, letterSpacing: 2, textTransform: 'uppercase', marginBottom: 6 }}>Спробуйте</div>
          <div style={{ fontSize: 24, fontWeight: 800 }}>Інтерактивний прототип</div>
          <div style={{ fontSize: 13, opacity: 0.55, marginTop: 4 }}>Натисніть «Увійти» щоб пройти потік авторизації, потім переходи між екранами</div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <InteractivePhone />
        </div>
      </div>

      {/* Footer */}
      <div style={{ textAlign: 'center', marginTop: 50, color: 'rgba(255,255,255,0.4)', fontSize: 12 }}>
        Тех. стек: Dart / Flutter (BLoC) → NestJS REST API → PostgreSQL 15 • Material Design 3 • #1565C0
      </div>
    </div>
  );
};

window.MedCareApp = App;
