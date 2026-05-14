import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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
import { LabTest, LabTestStatus } from '../lab-tests/entities/lab-test.entity';

@Injectable()
export class SeedService implements OnModuleInit {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    @InjectRepository(User)         private userRepo: Repository<User>,
    @InjectRepository(Doctor)       private doctorRepo: Repository<Doctor>,
    @InjectRepository(Patient)      private patientRepo: Repository<Patient>,
    @InjectRepository(Appointment)  private appointmentRepo: Repository<Appointment>,
    @InjectRepository(MedicalRecord)private medRecordRepo: Repository<MedicalRecord>,
    @InjectRepository(Medication)   private medicationRepo: Repository<Medication>,
    @InjectRepository(Prescription) private prescriptionRepo: Repository<Prescription>,
    @InjectRepository(Invoice)      private invoiceRepo: Repository<Invoice>,
    @InjectRepository(Ward)         private wardRepo: Repository<Ward>,
    @InjectRepository(LabTest)      private labTestRepo: Repository<LabTest>,
  ) {}

  async onModuleInit() {
    const count = await this.userRepo.count();
    if (count > 0) return;
    this.logger.log('Empty DB detected — seeding...');
    await this.run();
  }

  async run() {
    const hash  = await bcrypt.hash('password123', 12);
    const ahash = await bcrypt.hash('admin123', 12);

    // Users
    await this.userRepo.save(this.userRepo.create({
      email: 'admin@medcare.ua', password: ahash, role: UserRole.ADMIN,
      firstName: 'Адміністратор', lastName: 'Системи',
    }));
    const du = await this.userRepo.save([
      this.userRepo.create({ email: 'doctor@medcare.ua',  password: hash, role: UserRole.DOCTOR, firstName: 'Олена', lastName: 'Іваненко'   }),
      this.userRepo.create({ email: 'kardio@medcare.ua',  password: hash, role: UserRole.DOCTOR, firstName: 'Іван',  lastName: 'Коваленко'  }),
      this.userRepo.create({ email: 'neuro@medcare.ua',   password: hash, role: UserRole.DOCTOR, firstName: 'Марія', lastName: 'Бондаренко' }),
      this.userRepo.create({ email: 'surgeon@medcare.ua', password: hash, role: UserRole.DOCTOR, firstName: 'Петро', lastName: 'Шевченко'   }),
    ]);

    // Doctors
    const doctors = await this.doctorRepo.save([
      this.doctorRepo.create({ userId: du[0].id, firstName: 'Олена', lastName: 'Іваненко',   specialization: 'Загальна практика', licenseNo: 'UA-GP-00123', officeNumber: '101' }),
      this.doctorRepo.create({ userId: du[1].id, firstName: 'Іван',  lastName: 'Коваленко',  specialization: 'Кардіологія',       licenseNo: 'UA-CD-00456', officeNumber: '305' }),
      this.doctorRepo.create({ userId: du[2].id, firstName: 'Марія', lastName: 'Бондаренко', specialization: 'Неврологія',        licenseNo: 'UA-NR-00789', officeNumber: '207' }),
      this.doctorRepo.create({ userId: du[3].id, firstName: 'Петро', lastName: 'Шевченко',   specialization: 'Хірургія',          licenseNo: 'UA-SG-01234', officeNumber: '402' }),
    ]);

    // Patients
    const patients = await this.patientRepo.save([
      this.patientRepo.create({ firstName: 'Олексій', lastName: 'Петренко', middleName: 'Іванович',   birthDate: '1978-03-15', phone: '+380671234567', insuranceNo: 'UA-2024-8847261', bloodGroup: 'II',  rhFactor: '+', allergies: ['Пеніцилін'],             primaryDoctorId: doctors[1].id }),
      this.patientRepo.create({ firstName: 'Марина',  lastName: 'Коваль',   middleName: 'Степанівна', birthDate: '1990-07-22', phone: '+380502345678', insuranceNo: 'UA-2024-5521847', bloodGroup: 'I',   rhFactor: '+', allergies: [],                        primaryDoctorId: doctors[0].id }),
      this.patientRepo.create({ firstName: 'Степан',  lastName: 'Бойко',    middleName: 'Михайлович', birthDate: '1955-11-08', phone: '+380633456789', insuranceNo: 'UA-2023-3341592', bloodGroup: 'III', rhFactor: '-', allergies: ['Аспірин', 'Ібупрофен'], primaryDoctorId: doctors[2].id }),
      this.patientRepo.create({ firstName: 'Оксана',  lastName: 'Мельник',  middleName: 'Василівна',  birthDate: '1985-04-30', phone: '+380674567890', insuranceNo: 'UA-2024-7789234', bloodGroup: 'IV',  rhFactor: '+', allergies: [],                        primaryDoctorId: doctors[0].id }),
      this.patientRepo.create({ firstName: 'Микола',  lastName: 'Лисенко',  middleName: 'Петрович',   birthDate: '1967-09-12', phone: '+380505678901', insuranceNo: 'UA-2024-1123456', bloodGroup: 'II',  rhFactor: '-', allergies: ['Сульфаніламіди'],        primaryDoctorId: doctors[1].id }),
      this.patientRepo.create({ firstName: 'Ірина',   lastName: 'Савченко', middleName: 'Олегівна',   birthDate: '1995-06-18', phone: '+380631112233', insuranceNo: 'UA-2024-3312456', bloodGroup: 'I',   rhFactor: '-', allergies: [],                        primaryDoctorId: doctors[2].id }),
      this.patientRepo.create({ firstName: 'Василь',  lastName: 'Ткаченко', middleName: 'Сергійович', birthDate: '1963-02-27', phone: '+380672223344', insuranceNo: 'UA-2023-9987654', bloodGroup: 'III', rhFactor: '+', allergies: ['Новокаїн'],              primaryDoctorId: doctors[3].id }),
    ]);

    // Appointments (today)
    const d = new Date();
    const t = (h: number, m = 0) => { const x = new Date(d); x.setHours(h, m, 0, 0); return x; };
    const e = (x: Date) => new Date(x.getTime() + 30 * 60000);

    const appointments = await this.appointmentRepo.save([
      this.appointmentRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, startTime: t(8,0),  endTime: e(t(8,0)),  status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.REPEAT     }),
      this.appointmentRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, startTime: t(8,30), endTime: e(t(8,30)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY    }),
      this.appointmentRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, startTime: t(9,0),  endTime: e(t(9,0)),  status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY    }),
      this.appointmentRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, startTime: t(9,30), endTime: e(t(9,30)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PREVENTIVE }),
      this.appointmentRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, startTime: t(10,0), endTime: e(t(10,0)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.REPEAT     }),
      this.appointmentRepo.create({ patientId: patients[5].id, doctorId: doctors[2].id, startTime: t(10,30),endTime: e(t(10,30)),status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PRIMARY    }),
      this.appointmentRepo.create({ patientId: patients[6].id, doctorId: doctors[3].id, startTime: t(11,0), endTime: e(t(11,0)), status: AppointmentStatus.SCHEDULED, reason: AppointmentReason.PREVENTIVE }),
      this.appointmentRepo.create({ patientId: patients[0].id, doctorId: doctors[0].id, startTime: t(14,0), endTime: e(t(14,0)), status: AppointmentStatus.COMPLETED,  reason: AppointmentReason.REPEAT     }),
      this.appointmentRepo.create({ patientId: patients[1].id, doctorId: doctors[1].id, startTime: t(14,30),endTime: e(t(14,30)),status: AppointmentStatus.COMPLETED,  reason: AppointmentReason.PRIMARY    }),
    ]);

    // Medical records
    await this.medRecordRepo.save([
      this.medRecordRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, appointmentId: appointments[0].id, diagnosis: 'Гіпертонічна хвороба II стадія',  notes: { complaints: 'Головний біль', recommendations: 'Обмежити сіль' },         bloodPressure: '145/90', heartRate: 78, temperature: 36.6, weight: 82 }),
      this.medRecordRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, appointmentId: appointments[1].id, diagnosis: 'ГРВІ, гострий риніт',             notes: { complaints: 'Нежить, температура', recommendations: 'Постільний режим' }, bloodPressure: '120/80', heartRate: 85, temperature: 37.8, weight: 65 }),
      this.medRecordRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id,                                    diagnosis: 'Остеохондроз шийного відділу',    notes: { complaints: 'Болі в шиї' },                                               bloodPressure: '130/85', heartRate: 72, temperature: 36.4, weight: 88 }),
      this.medRecordRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, appointmentId: appointments[3].id, diagnosis: 'Профілактичний огляд, норма',     notes: { complaints: 'Скарг немає', recommendations: 'Огляд через рік' },          bloodPressure: '115/75', heartRate: 68, temperature: 36.5, weight: 61 }),
      this.medRecordRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id,                                    diagnosis: 'Цукровий діабет 2 типу',          notes: { complaints: 'Спрага, слабкість', recommendations: 'Дієта' },               bloodPressure: '140/88', heartRate: 80, temperature: 36.7, weight: 95 }),
      this.medRecordRepo.create({ patientId: patients[5].id, doctorId: doctors[2].id, appointmentId: appointments[5].id, diagnosis: 'Мігрень без аури',               notes: { complaints: 'Пульсуючий біль голови' },                                    bloodPressure: '118/76', heartRate: 74, temperature: 36.6, weight: 58 }),
      this.medRecordRepo.create({ patientId: patients[6].id, doctorId: doctors[3].id, appointmentId: appointments[6].id, diagnosis: 'Жовчнокам\'яна хвороба',         notes: { complaints: 'Болі в правому підребер\'ї' },                               bloodPressure: '125/82', heartRate: 76, temperature: 36.8, weight: 91 }),
    ]);

    // Medications
    await this.medicationRepo.save([
      { name: 'Амлодипін 5мг',        quantity: 500,  minQuantity: 50,  expiryDate: '2026-12-31', unit: 'таб.',  price: 45.50 },
      { name: 'Лозартан 50мг',        quantity: 320,  minQuantity: 50,  expiryDate: '2027-03-31', unit: 'таб.',  price: 78.20 },
      { name: 'Еналаприл 10мг',       quantity: 680,  minQuantity: 100, expiryDate: '2027-01-31', unit: 'таб.',  price: 22.80 },
      { name: 'Бісопролол 5мг',       quantity: 410,  minQuantity: 60,  expiryDate: '2027-04-30', unit: 'таб.',  price: 38.00 },
      { name: 'Аторвастатин 20мг',    quantity: 290,  minQuantity: 50,  expiryDate: '2027-02-28', unit: 'таб.',  price: 95.00 },
      { name: 'Аспірин Кардіо 100мг', quantity: 850,  minQuantity: 100, expiryDate: '2027-08-31', unit: 'таб.',  price: 18.50 },
      { name: 'Парацетамол 500мг',    quantity: 1200, minQuantity: 200, expiryDate: '2027-06-30', unit: 'таб.',  price: 12.50 },
      { name: 'Ібупрофен 400мг',      quantity: 45,   minQuantity: 100, expiryDate: '2026-11-30', unit: 'таб.',  price: 28.00 },
      { name: 'Диклофенак 50мг',      quantity: 360,  minQuantity: 60,  expiryDate: '2027-05-31', unit: 'таб.',  price: 24.00 },
      { name: 'Амоксицилін 500мг',    quantity: 220,  minQuantity: 50,  expiryDate: '2026-08-31', unit: 'капс.', price: 56.00 },
      { name: 'Метформін 500мг',      quantity: 15,   minQuantity: 100, expiryDate: '2026-09-30', unit: 'таб.',  price: 32.00 },
      { name: 'Левотироксин 50мкг',   quantity: 490,  minQuantity: 60,  expiryDate: '2027-06-30', unit: 'таб.',  price: 44.00 },
      { name: 'Омепразол 20мг',       quantity: 720,  minQuantity: 100, expiryDate: '2027-07-31', unit: 'капс.', price: 29.00 },
      { name: 'Лоратадин 10мг',       quantity: 550,  minQuantity: 80,  expiryDate: '2027-05-31', unit: 'таб.',  price: 21.00 },
      { name: 'Пірацетам 400мг',      quantity: 600,  minQuantity: 80,  expiryDate: '2027-09-30', unit: 'капс.', price: 35.00 },
      { name: 'Карбамазепін 200мг',   quantity: 280,  minQuantity: 50,  expiryDate: '2027-02-28', unit: 'таб.',  price: 52.00 },
      { name: 'Вітамін D3 2000 МО',   quantity: 310,  minQuantity: 50,  expiryDate: '2027-10-31', unit: 'капс.', price: 68.00 },
      { name: 'Магній B6',            quantity: 25,   minQuantity: 50,  expiryDate: '2026-06-30', unit: 'таб.',  price: 75.00 },
      { name: 'Цетиризин 10мг',       quantity: 380,  minQuantity: 60,  expiryDate: '2027-04-30', unit: 'таб.',  price: 19.50 },
      { name: 'Азитроміцин 500мг',    quantity: 30,   minQuantity: 40,  expiryDate: '2026-07-31', unit: 'таб.',  price: 89.00 },
    ].map(m => this.medicationRepo.create(m)));

    // Prescriptions
    await this.prescriptionRepo.save([
      this.prescriptionRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, items: [{ name: 'Амлодипін 5мг',      dosage: '1 таб.',   frequency: '1 р/день', duration: '30 днів',  instruction: 'Вранці до їжі'  }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[0].id, doctorId: doctors[1].id, items: [{ name: 'Лозартан 50мг',      dosage: '1 таб.',   frequency: '1 р/день', duration: '30 днів',  instruction: 'Ввечері'         }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, items: [{ name: 'Парацетамол 500мг',  dosage: '1-2 таб.', frequency: '3 р/день', duration: '5 днів',   instruction: 'При температурі' }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[1].id, doctorId: doctors[0].id, items: [{ name: 'Омепразол 20мг',     dosage: '1 капс.',  frequency: '1 р/день', duration: '14 днів',  instruction: 'До їжі'          }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, items: [{ name: 'Диклофенак 50мг',    dosage: '1 таб.',   frequency: '2 р/день', duration: '7 днів',   instruction: 'Після їжі'       }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[2].id, doctorId: doctors[2].id, items: [{ name: 'Пірацетам 400мг',    dosage: '2 капс.',  frequency: '3 р/день', duration: '30 днів',  instruction: ''                }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[3].id, doctorId: doctors[0].id, items: [{ name: 'Левотироксин 50мкг', dosage: '1 таб.',   frequency: '1 р/день', duration: 'постійно', instruction: 'Натщесерце'      }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, items: [{ name: 'Метформін 500мг',    dosage: '1 таб.',   frequency: '2 р/день', duration: 'постійно', instruction: 'Під час їжі'     }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[4].id, doctorId: doctors[1].id, items: [{ name: 'Аторвастатин 20мг',  dosage: '1 таб.',   frequency: '1 р/день', duration: 'постійно', instruction: 'Ввечері'         }], status: 'active' }),
      this.prescriptionRepo.create({ patientId: patients[5].id, doctorId: doctors[2].id, items: [{ name: 'Карбамазепін 200мг', dosage: '1 таб.',   frequency: '2 р/день', duration: '30 днів',  instruction: 'Під час їжі'     }], status: 'active' }),
    ]);

    // Lab tests
    await this.labTestRepo.save([
      this.labTestRepo.create({ patientId: patients[0].id, testName: 'Загальний аналіз крові', result: 'Гемоглобін 138 г/л, Лейкоцити 6.2', status: LabTestStatus.NORMAL,   notes: 'Норма'                       }),
      this.labTestRepo.create({ patientId: patients[0].id, testName: 'Ліпідний профіль',       result: 'ЗХС 6.1, ЛПНЩ 3.9, ЛПВЩ 1.1',      status: LabTestStatus.ABNORMAL, notes: 'Помірна гіперхолестеринемія' }),
      this.labTestRepo.create({ patientId: patients[1].id, testName: 'Загальний аналіз сечі',  result: 'Питома вага 1.018, Білок відсутній', status: LabTestStatus.NORMAL,   notes: 'Без патології'               }),
      this.labTestRepo.create({ patientId: patients[1].id, testName: 'ТТГ',                    result: '',                                  status: LabTestStatus.PENDING,  notes: 'В очікуванні'                }),
      this.labTestRepo.create({ patientId: patients[2].id, testName: 'МРТ шийного відділу',    result: 'Протрузія С5-С6 2мм',               status: LabTestStatus.ABNORMAL, notes: 'Направлення до нейрохірурга' }),
      this.labTestRepo.create({ patientId: patients[2].id, testName: 'Загальний аналіз крові', result: 'Гемоглобін 125 г/л, ШОЕ 18',       status: LabTestStatus.ABNORMAL, notes: 'Легка анемія'                }),
      this.labTestRepo.create({ patientId: patients[3].id, testName: 'ЕКГ',                    result: 'Синусовий ритм, ЧСС 72/хв',         status: LabTestStatus.NORMAL,   notes: 'Норма'                       }),
      this.labTestRepo.create({ patientId: patients[4].id, testName: 'HbA1c',                  result: '7.2%',                              status: LabTestStatus.ABNORMAL, notes: 'Діабет під контролем'        }),
      this.labTestRepo.create({ patientId: patients[4].id, testName: 'Глюкоза крові',          result: '8.1 ммоль/л',                       status: LabTestStatus.ABNORMAL, notes: 'Підвищена'                   }),
      this.labTestRepo.create({ patientId: patients[5].id, testName: 'МРТ головного мозку',    result: '',                                  status: LabTestStatus.PENDING,  notes: 'Терміново'                   }),
      this.labTestRepo.create({ patientId: patients[6].id, testName: 'УЗД черевної порожнини', result: 'Конкременти 5-8мм',                 status: LabTestStatus.ABNORMAL, notes: 'Консультація хірурга'        }),
    ]);

    // Invoices
    await this.invoiceRepo.save([
      this.invoiceRepo.create({ patientId: patients[0].id, appointmentId: appointments[7].id, amount: 450, status: InvoiceStatus.PAID,    paidAt: new Date(), description: 'Консультація кардіолога'         }),
      this.invoiceRepo.create({ patientId: patients[1].id,                                    amount: 350, status: InvoiceStatus.PENDING,                  description: 'Консультація терапевта'           }),
      this.invoiceRepo.create({ patientId: patients[2].id, appointmentId: appointments[2].id, amount: 600, status: InvoiceStatus.PAID,    paidAt: new Date(), description: 'Консультація невролога + МРТ'   }),
      this.invoiceRepo.create({ patientId: patients[3].id,                                    amount: 250, status: InvoiceStatus.PENDING,                  description: 'Профілактичний огляд'             }),
      this.invoiceRepo.create({ patientId: patients[4].id, appointmentId: appointments[4].id, amount: 450, status: InvoiceStatus.PENDING,                  description: 'Повторна консультація кардіолога' }),
      this.invoiceRepo.create({ patientId: patients[5].id,                                    amount: 550, status: InvoiceStatus.PAID,    paidAt: new Date(), description: 'Консультація невролога'          }),
      this.invoiceRepo.create({ patientId: patients[6].id, appointmentId: appointments[6].id, amount: 700, status: InvoiceStatus.PENDING,                  description: 'Консультація хірурга + УЗД'       }),
    ]);

    // Wards
    await this.wardRepo.save([
      this.wardRepo.create({ name: 'Терапія 1',    capacity: 6, occupied: 4, departmentId: 1, department: 'Терапія'     }),
      this.wardRepo.create({ name: 'Терапія 2',    capacity: 6, occupied: 6, departmentId: 1, department: 'Терапія'     }),
      this.wardRepo.create({ name: 'Кардіологія 1',capacity: 4, occupied: 3, departmentId: 2, department: 'Кардіологія' }),
      this.wardRepo.create({ name: 'Хірургія 1',   capacity: 8, occupied: 5, departmentId: 3, department: 'Хірургія'    }),
      this.wardRepo.create({ name: 'Неврологія 1', capacity: 6, occupied: 2, departmentId: 4, department: 'Неврологія'  }),
    ]);

    this.logger.log('✅ Seed complete — doctor@medcare.ua / password123');
  }
}
