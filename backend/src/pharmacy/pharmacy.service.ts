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

  async createPrescription(dto: Partial<Prescription>) {
    const rx = this.prescriptionRepo.create(dto);
    return this.prescriptionRepo.save(rx);
  }
}
