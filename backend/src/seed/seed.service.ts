import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User, UserRole } from '../users/entities/user.entity';
import { Doctor } from '../doctors/entities/doctor.entity';
import { Medication } from '../pharmacy/entities/medication.entity';

@Injectable()
export class SeedService implements OnModuleInit {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Doctor) private doctorRepo: Repository<Doctor>,
    @InjectRepository(Medication) private medicationRepo: Repository<Medication>,
  ) {}

  async onModuleInit() {
    const doctorCount = await this.doctorRepo.count();
    if (doctorCount > 0) return;

    this.logger.log('No doctors found — running initial seed...');
    await this.seedDoctors();

    const medCount = await this.medicationRepo.count();
    if (medCount === 0) await this.seedMedications();

    this.logger.log('✅ Initial seed complete');
  }

  private async seedDoctors() {
    const hash = await bcrypt.hash('password123', 12);
    const adminHash = await bcrypt.hash('admin123', 12);

    const doctorData = [
      { email: 'doctor@medcare.ua', firstName: 'Олена', lastName: 'Іваненко', specialization: 'Загальна практика', licenseNo: 'UA-GP-00123', officeNumber: '101' },
      { email: 'kardio@medcare.ua', firstName: 'Іван', lastName: 'Коваленко', specialization: 'Кардіологія', licenseNo: 'UA-CD-00456', officeNumber: '305' },
      { email: 'neuro@medcare.ua', firstName: 'Марія', lastName: 'Бондаренко', specialization: 'Неврологія', licenseNo: 'UA-NR-00789', officeNumber: '207' },
      { email: 'surgeon@medcare.ua', firstName: 'Петро', lastName: 'Шевченко', specialization: 'Хірургія', licenseNo: 'UA-SG-01234', officeNumber: '402' },
    ];

    // Ensure admin exists
    const existingAdmin = await this.userRepo.findOne({ where: { email: 'admin@medcare.ua' } });
    if (!existingAdmin) {
      await this.userRepo.save(
        this.userRepo.create({ email: 'admin@medcare.ua', password: adminHash, role: UserRole.ADMIN, firstName: 'Адміністратор', lastName: 'Системи' }),
      );
    }

    for (const d of doctorData) {
      let user = await this.userRepo.findOne({ where: { email: d.email } });
      if (!user) {
        user = await this.userRepo.save(
          this.userRepo.create({ email: d.email, password: hash, role: UserRole.DOCTOR, firstName: d.firstName, lastName: d.lastName }),
        );
      }
      const exists = await this.doctorRepo.findOne({ where: { userId: user.id } });
      if (!exists) {
        await this.doctorRepo.save(
          this.doctorRepo.create({ userId: user.id, firstName: d.firstName, lastName: d.lastName, specialization: d.specialization, licenseNo: d.licenseNo, officeNumber: d.officeNumber }),
        );
      }
    }

    this.logger.log('Seeded 4 doctors');
  }

  private async seedMedications() {
    const meds = [
      { name: 'Амлодипін 5мг', quantity: 500, minQuantity: 50, expiryDate: '2026-12-31', unit: 'таб.', price: 45.50 },
      { name: 'Лозартан 50мг', quantity: 320, minQuantity: 50, expiryDate: '2027-03-31', unit: 'таб.', price: 78.20 },
      { name: 'Еналаприл 10мг', quantity: 680, minQuantity: 100, expiryDate: '2027-01-31', unit: 'таб.', price: 22.80 },
      { name: 'Бісопролол 5мг', quantity: 410, minQuantity: 60, expiryDate: '2027-04-30', unit: 'таб.', price: 38.00 },
      { name: 'Аторвастатин 20мг', quantity: 290, minQuantity: 50, expiryDate: '2027-02-28', unit: 'таб.', price: 95.00 },
      { name: 'Аспірин Кардіо 100мг', quantity: 850, minQuantity: 100, expiryDate: '2027-08-31', unit: 'таб.', price: 18.50 },
      { name: 'Парацетамол 500мг', quantity: 1200, minQuantity: 200, expiryDate: '2027-06-30', unit: 'таб.', price: 12.50 },
      { name: 'Ібупрофен 400мг', quantity: 45, minQuantity: 100, expiryDate: '2026-11-30', unit: 'таб.', price: 28.00 },
      { name: 'Кетопрофен 100мг', quantity: 180, minQuantity: 40, expiryDate: '2026-10-31', unit: 'капс.', price: 42.00 },
      { name: 'Диклофенак 50мг', quantity: 360, minQuantity: 60, expiryDate: '2027-05-31', unit: 'таб.', price: 24.00 },
      { name: 'Амоксицилін 500мг', quantity: 220, minQuantity: 50, expiryDate: '2026-08-31', unit: 'капс.', price: 56.00 },
      { name: 'Азитроміцин 500мг', quantity: 30, minQuantity: 40, expiryDate: '2026-07-31', unit: 'таб.', price: 89.00 },
      { name: 'Ципрофлоксацин 500мг', quantity: 150, minQuantity: 30, expiryDate: '2027-01-31', unit: 'таб.', price: 67.00 },
      { name: 'Метформін 500мг', quantity: 15, minQuantity: 100, expiryDate: '2026-09-30', unit: 'таб.', price: 32.00 },
      { name: 'Глібенкламід 5мг', quantity: 340, minQuantity: 50, expiryDate: '2027-03-31', unit: 'таб.', price: 28.50 },
      { name: 'Левотироксин 50мкг', quantity: 490, minQuantity: 60, expiryDate: '2027-06-30', unit: 'таб.', price: 44.00 },
      { name: 'Пірацетам 400мг', quantity: 600, minQuantity: 80, expiryDate: '2027-09-30', unit: 'капс.', price: 35.00 },
      { name: 'Карбамазепін 200мг', quantity: 280, minQuantity: 50, expiryDate: '2027-02-28', unit: 'таб.', price: 52.00 },
      { name: 'Омепразол 20мг', quantity: 720, minQuantity: 100, expiryDate: '2027-07-31', unit: 'капс.', price: 29.00 },
      { name: 'Метоклопрамід 10мг', quantity: 410, minQuantity: 60, expiryDate: '2026-12-31', unit: 'таб.', price: 16.50 },
      { name: 'Лоратадин 10мг', quantity: 550, minQuantity: 80, expiryDate: '2027-05-31', unit: 'таб.', price: 21.00 },
      { name: 'Цетиризин 10мг', quantity: 380, minQuantity: 60, expiryDate: '2027-04-30', unit: 'таб.', price: 19.50 },
      { name: 'Вітамін D3 2000 МО', quantity: 310, minQuantity: 50, expiryDate: '2027-10-31', unit: 'капс.', price: 68.00 },
      { name: 'Магній B6', quantity: 25, minQuantity: 50, expiryDate: '2026-06-30', unit: 'таб.', price: 75.00 },
    ];
    await this.medicationRepo.save(meds.map(m => this.medicationRepo.create(m)));
    this.logger.log('Seeded 24 medications');
  }
}
