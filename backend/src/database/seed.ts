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

const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'medcare',
  entities: [User, Doctor, Patient, Appointment, MedicalRecord, Medication, Prescription, Invoice, Ward],
  synchronize: true,
});

async function seed() {
  await AppDataSource.initialize();
  console.log('Connected to PostgreSQL');

  const userRepo = AppDataSource.getRepository(User);
  const doctorRepo = AppDataSource.getRepository(Doctor);
  const patientRepo = AppDataSource.getRepository(Patient);
  const appointmentRepo = AppDataSource.getRepository(Appointment);
  const medRecordRepo = AppDataSource.getRepository(MedicalRecord);
  const medicationRepo = AppDataSource.getRepository(Medication);
  const prescriptionRepo = AppDataSource.getRepository(Prescription);
  const invoiceRepo = AppDataSource.getRepository(Invoice);
  const wardRepo = AppDataSource.getRepository(Ward);

  // Users & Doctors
  const hash = await bcrypt.hash('password123', 12);
  const adminHash = await bcrypt.hash('admin123', 12);

  const adminUser = userRepo.create({ email: 'admin@medcare.ua', password: adminHash, role: UserRole.ADMIN, firstName: 'Адміністратор', lastName: 'Системи' });
  await userRepo.save(adminUser);

  const doctorUsers = await userRepo.save([
    userRepo.create({ email: 'doctor@medcare.ua', password: hash, role: UserRole.DOCTOR, firstName: 'Олена', lastName: 'Іваненко' }),
    userRepo.create({ email: 'kardio@medcare.ua', password: hash, role: UserRole.DOCTOR, firstName: 'Іван', lastName: 'Коваленко' }),
    userRepo.create({ email: 'neuro@medcare.ua', password: hash, role: UserRole.DOCTOR, firstName: 'Марія', lastName: 'Бондаренко' }),
    userRepo.create({ email: 'surgeon@medcare.ua', password: hash, role: UserRole.DOCTOR, firstName: 'Петро', lastName: 'Шевченко' }),
  ]);

  const doctors = await doctorRepo.save([
    doctorRepo.create({ userId: doctorUsers[0].id, firstName: 'Олена', lastName: 'Іваненко', specialization: 'Загальна практика', licenseNo: 'UA-GP-00123', officeNumber: '101' }),
    doctorRepo.create({ userId: doctorUsers[1].id, firstName: 'Іван', lastName: 'Коваленко', specialization: 'Кардіологія', licenseNo: 'UA-CD-00456', officeNumber: '305' }),
    doctorRepo.create({ userId: doctorUsers[2].id, firstName: 'Марія', lastName: 'Бондаренко', specialization: 'Неврологія', licenseNo: 'UA-NR-00789', officeNumber: '207' }),
    doctorRepo.create({ userId: doctorUsers[3].id, firstName: 'Петро', lastName: 'Шевченко', specialization: 'Хірургія', licenseNo: 'UA-SG-01234', officeNumber: '402' }),
  ]);

  // Patients
  const patients = await patientRepo.save([
    patientRepo.create({ firstName: 'Олексій', lastName: 'Петренко', middleName: 'Іванович', birthDate: '1978-03-15', phone: '+380671234567', insuranceNo: 'UA-2024-8847261', bloodGroup: 'II', rhFactor: '+', allergies: ['Пеніцилін'], primaryDoctorId: doctors[1].id }),
    patientRepo.create({ firstName: 'Марина', lastName: 'Коваль', middleName: 'Степанівна', birthDate: '1990-07-22', phone: '+380502345678', insuranceNo: 'UA-2024-5521847', bloodGroup: 'I', rhFactor: '+', allergies: [], primaryDoctorId: doctors[0].id }),
    patientRepo.create({ firstName: 'Степан', lastName: 'Бойко', middleName: 'Михайлович', birthDate: '1955-11-08', phone: '+380633456789', insuranceNo: 'UA-2023-3341592', bloodGroup: 'III', rhFactor: '-', allergies: ['Аспірин', 'Ібупрофен'], primaryDoctorId: doctors[2].id }),
    patientRepo.create({ firstName: 'Оксана', lastName: 'Мельник', middleName: 'Василівна', birthDate: '1985-04-30', phone: '+380674567890', insuranceNo: 'UA-2024-7789234', bloodGroup: 'IV', rhFactor: '+', allergies: [], primaryDoctorId: doctors[0].id }),
    patientRepo.create({ firstName: 'Микола', lastName: 'Лисенко', middleName: 'Петрович', birthDate: '1967-09-12', phone: '+380505678901', insuranceNo: 'UA-2024-1123456', bloodGroup: 'II', rhFactor: '-', allergies: ['Сульфаніламіди'], primaryDoctorId: doctors[1].id }),
  ]);

  // Today appointments
  const today = new Date();
  const makeTime = (h: number, m: number) => { const d = new Date(today); d.setHours(h, m, 0, 0); return d; };

  const appointments = await appointmentRepo.save([
    appointmentRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, startTime: makeTime(9, 0), endTime: makeTime(9, 30), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.REPEAT }),
    appointmentRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, startTime: makeTime(9, 30), endTime: makeTime(10, 0), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY }),
    appointmentRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, startTime: makeTime(10, 0), endTime: makeTime(10, 30), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY }),
    appointmentRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, startTime: makeTime(11, 0), endTime: makeTime(11, 30), status: AppointmentStatus.COMPLETED, reason: AppointmentReason.PREVENTIVE }),
    appointmentRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, startTime: makeTime(14, 0), endTime: makeTime(14, 30), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.REPEAT }),
  ]);

  // Medical records
  await medRecordRepo.save([
    medRecordRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, appointmentId: appointments[0].id, diagnosis: 'Гіпертонічна хвороба II стадія', notes: { complaints: 'Головний біль, запаморочення', recommendations: 'Обмежити споживання солі' }, bloodPressure: '145/90', heartRate: 78, temperature: 36.6, weight: 82 }),
    medRecordRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, appointmentId: appointments[1].id, diagnosis: 'ГРВІ, гострий риніт', notes: { complaints: 'Нежить, температура', recommendations: 'Постільний режим 3 дні' }, bloodPressure: '120/80', heartRate: 85, temperature: 37.8, weight: 65 }),
    medRecordRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, diagnosis: 'Остеохондроз шийного відділу', notes: { complaints: 'Болі в шиї та плечах' }, bloodPressure: '130/85', heartRate: 72, temperature: 36.4, weight: 88 }),
  ]);

  // Medications
  await medicationRepo.save([
    medicationRepo.create({ name: 'Амлодипін 5мг', quantity: 500, minQuantity: 50, expiryDate: '2026-12-31', unit: 'таб.', price: 45.50 }),
    medicationRepo.create({ name: 'Лозартан 50мг', quantity: 320, minQuantity: 50, expiryDate: '2027-03-31', unit: 'таб.', price: 78.20 }),
    medicationRepo.create({ name: 'Метформін 500мг', quantity: 15, minQuantity: 100, expiryDate: '2026-09-30', unit: 'таб.', price: 32.00 }),
    medicationRepo.create({ name: 'Парацетамол 500мг', quantity: 1200, minQuantity: 200, expiryDate: '2027-06-30', unit: 'таб.', price: 12.50 }),
    medicationRepo.create({ name: 'Ібупрофен 400мг', quantity: 45, minQuantity: 100, expiryDate: '2026-11-30', unit: 'таб.', price: 28.00 }),
    medicationRepo.create({ name: 'Еналаприл 10мг', quantity: 680, minQuantity: 100, expiryDate: '2027-01-31', unit: 'таб.', price: 22.80 }),
  ]);

  // Prescriptions
  await prescriptionRepo.save([
    prescriptionRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, items: [{ name: 'Амлодипін 5мг', dosage: '1 таб.', frequency: '1 р/день', duration: '30 днів' }, { name: 'Лозартан 50мг', dosage: '1 таб.', frequency: '1 р/день', duration: '30 днів' }] }),
    prescriptionRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, items: [{ name: 'Парацетамол 500мг', dosage: '1 таб.', frequency: '3 р/день', duration: '5 днів' }] }),
  ]);

  // Invoices
  await invoiceRepo.save([
    invoiceRepo.create({ patientId: patients[0].id, appointmentId: appointments[3].id, amount: 450, status: InvoiceStatus.PAID, paidAt: new Date(), description: 'Консультація кардіолога' }),
    invoiceRepo.create({ patientId: patients[1].id, amount: 350, status: InvoiceStatus.PENDING, description: 'Консультація терапевта' }),
    invoiceRepo.create({ patientId: patients[2].id, amount: 600, status: InvoiceStatus.PAID, paidAt: new Date(), description: 'Консультація невролога + МРТ' }),
    invoiceRepo.create({ patientId: patients[4].id, amount: 450, status: InvoiceStatus.PENDING, description: 'Повторна консультація кардіолога' }),
  ]);

  // Wards
  await wardRepo.save([
    wardRepo.create({ name: 'Терапія 1', capacity: 6, occupied: 4, departmentId: 1, department: 'Терапія' }),
    wardRepo.create({ name: 'Терапія 2', capacity: 6, occupied: 6, departmentId: 1, department: 'Терапія' }),
    wardRepo.create({ name: 'Кардіологія 1', capacity: 4, occupied: 3, departmentId: 2, department: 'Кардіологія' }),
    wardRepo.create({ name: 'Хірургія 1', capacity: 8, occupied: 5, departmentId: 3, department: 'Хірургія' }),
    wardRepo.create({ name: 'Неврологія 1', capacity: 6, occupied: 2, departmentId: 4, department: 'Неврологія' }),
  ]);

  console.log('✅ Seed completed! Database populated with test data.');
  console.log('   Accounts:');
  console.log('   admin@medcare.ua / admin123 (Admin)');
  console.log('   doctor@medcare.ua / password123 (Dr. Іваненко — Загальна практика)');
  console.log('   kardio@medcare.ua / password123 (Dr. Коваленко — Кардіологія)');

  await AppDataSource.destroy();
}

seed().catch((e) => { console.error(e); process.exit(1); });
