import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Medication } from './entities/medication.entity';
import { Prescription } from './entities/prescription.entity';

@Injectable()
export class PharmacyService {
  constructor(
    @InjectRepository(Medication) private medicationRepo: Repository<Medication>,
    @InjectRepository(Prescription) private prescriptionRepo: Repository<Prescription>,
  ) {}

  // Medications
  findAllMedications() {
    return this.medicationRepo.find({ order: { name: 'ASC' } });
  }

  findLowStock() {
    return this.medicationRepo.createQueryBuilder('m')
      .where('m.quantity <= m.minQuantity')
      .getMany();
  }

  async createMedication(dto: Partial<Medication>) {
    const med = this.medicationRepo.create(dto);
    return this.medicationRepo.save(med);
  }

  async updateMedication(id: string, dto: Partial<Medication>) {
    const med = await this.medicationRepo.findOne({ where: { id } });
    if (!med) throw new NotFoundException('Медикамент не знайдено');
    await this.medicationRepo.update(id, dto);
    return this.medicationRepo.findOne({ where: { id } });
  }

  // Prescriptions
  findPrescriptionsByPatient(patientId: string) {
    return this.prescriptionRepo.find({ where: { patientId }, order: { issuedAt: 'DESC' } });
  }

  async createPrescription(dto: any) {
    // Якщо дані приходять з нашої нової форми (фронтенд)
    if (dto.medicationName) {
      const data: any = {
        patientId: dto.patientId,
        doctorId: dto.doctorId || 'f197d12c-80bc-4480-aa24-dc41f27b1f91',
        items: [{
          name: dto.medicationName,
          dosage: dto.dosage,
          instruction: dto.instruction || '',
        }],
        status: dto.status || 'active',
      };
      const rx = this.prescriptionRepo.create(data);
      return this.prescriptionRepo.save(rx);
    }
    // Старий формат
    const rx = this.prescriptionRepo.create(dto as Partial<Prescription>);
    return this.prescriptionRepo.save(rx);
  }
}
