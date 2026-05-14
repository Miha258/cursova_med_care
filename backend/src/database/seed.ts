import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User, UserRole } from '../users/entities/user.entity';
import { Doctor } from '../doctors/entities/doctor.entity';
import { Patient } from '../patients/entities/patient.entity';
import { Appointment, AppointmentStatus, AppointmentReason } from '../appointments/entities/appointment.entity';
import { MedicalRecord } from '../medical-records/entities/medical-record.entity';
import { Medication } from '../pharmacy/entities/medication.entity';
import { Prescription } from '../pharmacy/entities/prescription.entity';
import { Invoice, InvoiceStatus } from '../finance/entities/invoice.entity';
import { Ward } from '../wards/entities/ward.entity';
import { LabTest } from '../lab-tests/entities/lab-test.entity';

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'medcare',
  entities: [User, Doctor, Patient, Appointment, MedicalRecord, Medication, Prescription, Invoice, Ward, LabTest],
  synchronize: true,
});

async function seed() {
  await AppDataSource.initialize();
  console.log('✅ Connected to PostgreSQL');

  // Очистити все
  await AppDataSource.query(`
    TRUNCATE TABLE
      lab_tests, prescriptions, medical_records, invoices,
      appointments, medications, patients, doctors, users, wards
    RESTART IDENTITY CASCADE
  `);
  console.log('🗑️  Cleared all tables');

  const userRepo   = AppDataSource.getRepository(User);
  const doctorRepo = AppDataSource.getRepository(Doctor);
  const patientRepo = AppDataSource.getRepository(Patient);
  const appointmentRepo = AppDataSource.getRepository(Appointment);
  const medRecordRepo = AppDataSource.getRepository(MedicalRecord);
  const medicationRepo = AppDataSource.getRepository(Medication);
  const prescriptionRepo = AppDataSource.getRepository(Prescription);
  const invoiceRepo = AppDataSource.getRepository(Invoice);
  const wardRepo = AppDataSource.getRepository(Ward);
  const labTestRepo = AppDataSource.getRepository(LabTest);

  const hash  = await bcrypt.hash('password123', 12);
  const ahash = await bcrypt.hash('admin123', 12);

  // ── USERS ──────────────────────────────────────────────────────────────────
  const adminUser = await userRepo.save(userRepo.create({
    email: 'admin@medcare.ua', password: ahash, role: UserRole.ADMIN,
    firstName: 'Адміністратор', lastName: 'Системи',
  }));

  const doctorUsers = await userRepo.save([
    userRepo.create({ email: 'doctor@medcare.ua',  password: hash, role: UserRole.DOCTOR, firstName: 'Олена', lastName: 'Іваненко'   }),
    userRepo.create({ email: 'kardio@medcare.ua',  password: hash, role: UserRole.DOCTOR, firstName: 'Іван',  lastName: 'Коваленко'  }),
    userRepo.create({ email: 'neuro@medcare.ua',   password: hash, role: UserRole.DOCTOR, firstName: 'Марія', lastName: 'Бондаренко' }),
    userRepo.create({ email: 'surgeon@medcare.ua', password: hash, role: UserRole.DOCTOR, firstName: 'Петро', lastName: 'Шевченко'   }),
  ]);
  console.log('✅ Users:', doctorUsers.length + 1);

  // ── DOCTORS ────────────────────────────────────────────────────────────────
  const doctors = await doctorRepo.save([
    doctorRepo.create({ userId: doctorUsers[0].id, firstName: 'Олена', lastName: 'Іваненко',   specialization: 'Загальна практика', licenseNo: 'UA-GP-00123', officeNumber: '101' }),
    doctorRepo.create({ userId: doctorUsers[1].id, firstName: 'Іван',  lastName: 'Коваленко',  specialization: 'Кардіологія',       licenseNo: 'UA-CD-00456', officeNumber: '305' }),
    doctorRepo.create({ userId: doctorUsers[2].id, firstName: 'Марія', lastName: 'Бондаренко', specialization: 'Неврологія',        licenseNo: 'UA-NR-00789', officeNumber: '207' }),
    doctorRepo.create({ userId: doctorUsers[3].id, firstName: 'Петро', lastName: 'Шевченко',   specialization: 'Хірургія',          licenseNo: 'UA-SG-01234', officeNumber: '402' }),
  ]);
  console.log('✅ Doctors:', doctors.length);

  // ── PATIENTS ───────────────────────────────────────────────────────────────
  const patients = await patientRepo.save([
    patientRepo.create({ firstName: 'Олексій', lastName: 'Петренко', middleName: 'Іванович',   birthDate: '1978-03-15', phone: '+380671234567', email: 'petrenkooa@gmail.com', insuranceNo: 'UA-2024-8847261', bloodGroup: 'II',  rhFactor: '+', allergies: ['Пеніцилін'],             primaryDoctorId: doctors[1].id }),
    patientRepo.create({ firstName: 'Марина',  lastName: 'Коваль',   middleName: 'Степанівна', birthDate: '1990-07-22', phone: '+380502345678', email: 'koval.m@ukr.net',       insuranceNo: 'UA-2024-5521847', bloodGroup: 'I',   rhFactor: '+', allergies: [],                        primaryDoctorId: doctors[0].id }),
    patientRepo.create({ firstName: 'Степан',  lastName: 'Бойко',    middleName: 'Михайлович', birthDate: '1955-11-08', phone: '+380633456789', email: 'boyko.s@gmail.com',     insuranceNo: 'UA-2023-3341592', bloodGroup: 'III', rhFactor: '-', allergies: ['Аспірин', 'Ібупрофен'], primaryDoctorId: doctors[2].id }),
    patientRepo.create({ firstName: 'Оксана',  lastName: 'Мельник',  middleName: 'Василівна',  birthDate: '1985-04-30', phone: '+380674567890', email: 'melnyk.o@gmail.com',    insuranceNo: 'UA-2024-7789234', bloodGroup: 'IV',  rhFactor: '+', allergies: [],                        primaryDoctorId: doctors[0].id }),
    patientRepo.create({ firstName: 'Микола',  lastName: 'Лисенко',  middleName: 'Петрович',   birthDate: '1967-09-12', phone: '+380505678901', email: 'lysenko.m@ukr.net',     insuranceNo: 'UA-2024-1123456', bloodGroup: 'II',  rhFactor: '-', allergies: ['Сульфаніламіди'],        primaryDoctorId: doctors[1].id }),
    patientRepo.create({ firstName: 'Ірина',   lastName: 'Савченко', middleName: 'Олегівна',   birthDate: '1995-06-18', phone: '+380631112233', email: 'savchenko.i@gmail.com', insuranceNo: 'UA-2024-3312456', bloodGroup: 'I',   rhFactor: '-', allergies: [],                        primaryDoctorId: doctors[2].id }),
    patientRepo.create({ firstName: 'Василь',  lastName: 'Ткаченко', middleName: 'Сергійович', birthDate: '1963-02-27', phone: '+380672223344', email: 'tkachenko.v@ukr.net',   insuranceNo: 'UA-2023-9987654', bloodGroup: 'III', rhFactor: '+', allergies: ['Новокаїн'],              primaryDoctorId: doctors[3].id }),
  ]);
  console.log('✅ Patients:', patients.length);

  // ── APPOINTMENTS ───────────────────────────────────────────────────────────
  const today = new Date();
  const t = (h: number, m = 0) => { const d = new Date(today); d.setHours(h, m, 0, 0); return d; };
  const end = (d: Date) => new Date(d.getTime() + 30 * 60 * 1000);

  const appointments = await appointmentRepo.save([
    appointmentRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, startTime: t(8,0),  endTime: end(t(8,0)),  status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.REPEAT     }),
    appointmentRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, startTime: t(8,30), endTime: end(t(8,30)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY    }),
    appointmentRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, startTime: t(9,0),  endTime: end(t(9,0)),  status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY    }),
    appointmentRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, startTime: t(9,30), endTime: end(t(9,30)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PREVENTIVE }),
    appointmentRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, startTime: t(10,0), endTime: end(t(10,0)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.REPEAT     }),
    appointmentRepo.create({ patientId: patients[5].id, doctorId: doctors[2].id, startTime: t(10,30),endTime: end(t(10,30)),status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY    }),
    appointmentRepo.create({ patientId: patients[6].id, doctorId: doctors[3].id, startTime: t(11,0), endTime: end(t(11,0)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PREVENTIVE }),
    appointmentRepo.create({ patientId: patients[0].id, doctorId: doctors[0].id, startTime: t(14,0), endTime: end(t(14,0)), status: AppointmentStatus.COMPLETED,  reason: AppointmentReason.REPEAT     }),
    appointmentRepo.create({ patientId: patients[1].id, doctorId: doctors[1].id, startTime: t(14,30),endTime: end(t(14,30)),status: AppointmentStatus.COMPLETED,  reason: AppointmentReason.PRIMARY    }),
    appointmentRepo.create({ patientId: patients[2].id, doctorId: doctors[3].id, startTime: t(15,0), endTime: end(t(15,0)), status: AppointmentStatus.CANCELLED,  reason: AppointmentReason.PREVENTIVE }),
  ]);
  console.log('✅ Appointments:', appointments.length);

  // ── MEDICAL RECORDS ────────────────────────────────────────────────────────
  await medRecordRepo.save([
    medRecordRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, appointmentId: appointments[0].id, diagnosis: 'Гіпертонічна хвороба II стадія',     notes: { complaints: 'Головний біль, запаморочення', recommendations: 'Обмежити сіль' },      bloodPressure: '145/90', heartRate: 78, temperature: 36.6, weight: 82 }),
    medRecordRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, appointmentId: appointments[1].id, diagnosis: 'ГРВІ, гострий риніт',               notes: { complaints: 'Нежить, температура',          recommendations: 'Постільний режим 3 дні' }, bloodPressure: '120/80', heartRate: 85, temperature: 37.8, weight: 65 }),
    medRecordRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id,                                    diagnosis: 'Остеохондроз шийного відділу',       notes: { complaints: 'Болі в шиї та плечах' },                                                bloodPressure: '130/85', heartRate: 72, temperature: 36.4, weight: 88 }),
    medRecordRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, appointmentId: appointments[3].id, diagnosis: 'Профілактичний огляд, норма',        notes: { complaints: 'Скарг немає',                  recommendations: 'Повторний огляд через рік' }, bloodPressure: '115/75', heartRate: 68, temperature: 36.5, weight: 61 }),
    medRecordRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id,                                    diagnosis: 'Цукровий діабет 2 типу',             notes: { complaints: 'Спрага, слабкість',             recommendations: 'Дієта, контроль глюкози' }, bloodPressure: '140/88', heartRate: 80, temperature: 36.7, weight: 95 }),
    medRecordRepo.create({ patientId: patients[5].id, doctorId: doctors[2].id, appointmentId: appointments[5].id, diagnosis: 'Мігрень без аури',                  notes: { complaints: 'Пульсуючий біль голови',       recommendations: 'Уникати яскравого світла' }, bloodPressure: '118/76', heartRate: 74, temperature: 36.6, weight: 58 }),
    medRecordRepo.create({ patientId: patients[6].id, doctorId: doctors[3].id, appointmentId: appointments[6].id, diagnosis: 'Жовчнокам\'яна хвороба',            notes: { complaints: 'Болі в правому підребер\'ї',   recommendations: 'УЗД черевної порожнини' },   bloodPressure: '125/82', heartRate: 76, temperature: 36.8, weight: 91 }),
  ]);
  console.log('✅ Medical records: 7');

  // ── MEDICATIONS ────────────────────────────────────────────────────────────
  await medicationRepo.save([
    medicationRepo.create({ name: 'Амлодипін 5мг',        quantity: 500,  minQuantity: 50,  expiryDate: '2026-12-31', unit: 'таб.',  price: 45.50 }),
    medicationRepo.create({ name: 'Лозартан 50мг',        quantity: 320,  minQuantity: 50,  expiryDate: '2027-03-31', unit: 'таб.',  price: 78.20 }),
    medicationRepo.create({ name: 'Еналаприл 10мг',       quantity: 680,  minQuantity: 100, expiryDate: '2027-01-31', unit: 'таб.',  price: 22.80 }),
    medicationRepo.create({ name: 'Бісопролол 5мг',       quantity: 410,  minQuantity: 60,  expiryDate: '2027-04-30', unit: 'таб.',  price: 38.00 }),
    medicationRepo.create({ name: 'Аторвастатин 20мг',    quantity: 290,  minQuantity: 50,  expiryDate: '2027-02-28', unit: 'таб.',  price: 95.00 }),
    medicationRepo.create({ name: 'Аспірин Кардіо 100мг', quantity: 850,  minQuantity: 100, expiryDate: '2027-08-31', unit: 'таб.',  price: 18.50 }),
    medicationRepo.create({ name: 'Парацетамол 500мг',    quantity: 1200, minQuantity: 200, expiryDate: '2027-06-30', unit: 'таб.',  price: 12.50 }),
    medicationRepo.create({ name: 'Ібупрофен 400мг',      quantity: 45,   minQuantity: 100, expiryDate: '2026-11-30', unit: 'таб.',  price: 28.00 }),
    medicationRepo.create({ name: 'Диклофенак 50мг',      quantity: 360,  minQuantity: 60,  expiryDate: '2027-05-31', unit: 'таб.',  price: 24.00 }),
    medicationRepo.create({ name: 'Амоксицилін 500мг',    quantity: 220,  minQuantity: 50,  expiryDate: '2026-08-31', unit: 'капс.', price: 56.00 }),
    medicationRepo.create({ name: 'Азитроміцин 500мг',    quantity: 30,   minQuantity: 40,  expiryDate: '2026-07-31', unit: 'таб.',  price: 89.00 }),
    medicationRepo.create({ name: 'Метформін 500мг',      quantity: 15,   minQuantity: 100, expiryDate: '2026-09-30', unit: 'таб.',  price: 32.00 }),
    medicationRepo.create({ name: 'Левотироксин 50мкг',   quantity: 490,  minQuantity: 60,  expiryDate: '2027-06-30', unit: 'таб.',  price: 44.00 }),
    medicationRepo.create({ name: 'Омепразол 20мг',       quantity: 720,  minQuantity: 100, expiryDate: '2027-07-31', unit: 'капс.', price: 29.00 }),
    medicationRepo.create({ name: 'Лоратадин 10мг',       quantity: 550,  minQuantity: 80,  expiryDate: '2027-05-31', unit: 'таб.',  price: 21.00 }),
    medicationRepo.create({ name: 'Пірацетам 400мг',      quantity: 600,  minQuantity: 80,  expiryDate: '2027-09-30', unit: 'капс.', price: 35.00 }),
    medicationRepo.create({ name: 'Карбамазепін 200мг',   quantity: 280,  minQuantity: 50,  expiryDate: '2027-02-28', unit: 'таб.',  price: 52.00 }),
    medicationRepo.create({ name: 'Вітамін D3 2000 МО',   quantity: 310,  minQuantity: 50,  expiryDate: '2027-10-31', unit: 'капс.', price: 68.00 }),
    medicationRepo.create({ name: 'Магній B6',            quantity: 25,   minQuantity: 50,  expiryDate: '2026-06-30', unit: 'таб.',  price: 75.00 }),
    medicationRepo.create({ name: 'Цетиризин 10мг',       quantity: 380,  minQuantity: 60,  expiryDate: '2027-04-30', unit: 'таб.',  price: 19.50 }),
  ]);
  console.log('✅ Medications: 20');

  // ── PRESCRIPTIONS ──────────────────────────────────────────────────────────
  await prescriptionRepo.save([
    prescriptionRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, items: [{ name: 'Амлодипін 5мг',      dosage: '1 таб.',   frequency: '1 р/день', duration: '30 днів',  instruction: 'Вранці до їжі'   }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, items: [{ name: 'Лозартан 50мг',      dosage: '1 таб.',   frequency: '1 р/день', duration: '30 днів',  instruction: 'Ввечері'          }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, items: [{ name: 'Парацетамол 500мг',  dosage: '1-2 таб.', frequency: '3 р/день', duration: '5 днів',   instruction: 'При температурі'  }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, items: [{ name: 'Омепразол 20мг',     dosage: '1 капс.',  frequency: '1 р/день', duration: '14 днів',  instruction: 'До їжі'           }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, items: [{ name: 'Диклофенак 50мг',    dosage: '1 таб.',   frequency: '2 р/день', duration: '7 днів',   instruction: 'Після їжі'        }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, items: [{ name: 'Пірацетам 400мг',    dosage: '2 капс.',  frequency: '3 р/день', duration: '30 днів',  instruction: ''                 }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, items: [{ name: 'Левотироксин 50мкг', dosage: '1 таб.',   frequency: '1 р/день', duration: 'постійно', instruction: 'Натщесерце'       }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, items: [{ name: 'Метформін 500мг',    dosage: '1 таб.',   frequency: '2 р/день', duration: 'постійно', instruction: 'Під час їжі'      }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, items: [{ name: 'Аторвастатин 20мг',  dosage: '1 таб.',   frequency: '1 р/день', duration: 'постійно', instruction: 'Ввечері'          }], status: 'active' }),
    prescriptionRepo.create({ patientId: patients[5].id, doctorId: doctors[2].id, items: [{ name: 'Карбамазепін 200мг', dosage: '1 таб.',   frequency: '2 р/день', duration: '30 днів',  instruction: 'Під час їжі'      }], status: 'active' }),
  ]);
  console.log('✅ Prescriptions: 10');

  // ── LAB TESTS ──────────────────────────────────────────────────────────────
  await labTestRepo.save([
    labTestRepo.create({ patientId: patients[0].id, testName: 'Загальний аналіз крові',   result: 'Гемоглобін 138 г/л, Лейкоцити 6.2×10⁹/л', status: 'completed', notes: 'Норма'                       }),
    labTestRepo.create({ patientId: patients[0].id, testName: 'Ліпідний профіль',         result: 'ЗХС 6.1, ЛПНЩ 3.9, ЛПВЩ 1.1',             status: 'completed', notes: 'Помірна гіперхолестеринемія' }),
    labTestRepo.create({ patientId: patients[1].id, testName: 'Загальний аналіз сечі',    result: 'Питома вага 1.018, Білок відсутній',         status: 'completed', notes: 'Без патології'               }),
    labTestRepo.create({ patientId: patients[1].id, testName: 'ТТГ',                      result: 'В очікуванні',                              status: 'pending',   notes: ''                            }),
    labTestRepo.create({ patientId: patients[2].id, testName: 'МРТ шийного відділу',      result: 'Протрузія С5-С6 2мм',                       status: 'completed', notes: 'Направлення до нейрохірурга' }),
    labTestRepo.create({ patientId: patients[2].id, testName: 'Загальний аналіз крові',   result: 'Гемоглобін 125 г/л, ШОЕ 18',              status: 'completed', notes: 'Легка анемія'                }),
    labTestRepo.create({ patientId: patients[3].id, testName: 'ЕКГ',                      result: 'Синусовий ритм, ЧСС 72/хв',                 status: 'completed', notes: 'Норма'                       }),
    labTestRepo.create({ patientId: patients[4].id, testName: 'HbA1c',                    result: '7.2%',                                      status: 'completed', notes: 'Діабет під контролем'        }),
    labTestRepo.create({ patientId: patients[4].id, testName: 'Глюкоза крові',            result: '8.1 ммоль/л',                               status: 'completed', notes: 'Підвищена'                   }),
    labTestRepo.create({ patientId: patients[5].id, testName: 'МРТ головного мозку',      result: 'В очікуванні',                              status: 'pending',   notes: 'Терміново'                   }),
    labTestRepo.create({ patientId: patients[6].id, testName: 'УЗД черевної порожнини',   result: 'Жовчний міхур: конкременти 5-8мм',          status: 'completed', notes: 'Консультація хірурга'        }),
  ]);
  console.log('✅ Lab tests: 11');

  // ── INVOICES ───────────────────────────────────────────────────────────────
  await invoiceRepo.save([
    invoiceRepo.create({ patientId: patients[0].id, appointmentId: appointments[7].id, amount: 450, status: InvoiceStatus.PAID,    paidAt: new Date(), description: 'Консультація кардіолога'          }),
    invoiceRepo.create({ patientId: patients[1].id,                                    amount: 350, status: InvoiceStatus.PENDING,                  description: 'Консультація терапевта'            }),
    invoiceRepo.create({ patientId: patients[2].id, appointmentId: appointments[2].id, amount: 600, status: InvoiceStatus.PAID,    paidAt: new Date(), description: 'Консультація невролога + МРТ'    }),
    invoiceRepo.create({ patientId: patients[3].id,                                    amount: 250, status: InvoiceStatus.PENDING,                  description: 'Профілактичний огляд'              }),
    invoiceRepo.create({ patientId: patients[4].id, appointmentId: appointments[4].id, amount: 450, status: InvoiceStatus.PENDING,                  description: 'Повторна консультація кардіолога'  }),
    invoiceRepo.create({ patientId: patients[5].id,                                    amount: 550, status: InvoiceStatus.PAID,    paidAt: new Date(), description: 'Консультація невролога'           }),
    invoiceRepo.create({ patientId: patients[6].id, appointmentId: appointments[6].id, amount: 700, status: InvoiceStatus.PENDING,                  description: 'Консультація хірурга + УЗД'        }),
  ]);
  console.log('✅ Invoices: 7');

  // ── WARDS ──────────────────────────────────────────────────────────────────
  await wardRepo.save([
    wardRepo.create({ name: 'Терапія 1',    capacity: 6, occupied: 4, departmentId: 1, department: 'Терапія'    }),
    wardRepo.create({ name: 'Терапія 2',    capacity: 6, occupied: 6, departmentId: 1, department: 'Терапія'    }),
    wardRepo.create({ name: 'Кардіологія 1',capacity: 4, occupied: 3, departmentId: 2, department: 'Кардіологія'}),
    wardRepo.create({ name: 'Хірургія 1',   capacity: 8, occupied: 5, departmentId: 3, department: 'Хірургія'   }),
    wardRepo.create({ name: 'Неврологія 1', capacity: 6, occupied: 2, departmentId: 4, department: 'Неврологія' }),
  ]);
  console.log('✅ Wards: 5');

  console.log('\n🎉 Seed complete!');
  console.log('   doctor@medcare.ua  / password123');
  console.log('   admin@medcare.ua   / admin123');

  await AppDataSource.destroy();
}

seed().catch(e => { console.error('❌ Seed failed:', e.message); process.exit(1); });
