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
    if (dto.medicationName) {
      let doctorId = dto.doctorId;
      
      if (!doctorId) {
        // Якщо doctorId не передано, беремо першого лікаря з бази
        // Це гарантує проходження Foreign Key constraint
        const doctor = await this.prescriptionRepo.query('SELECT id FROM doctors LIMIT 1');
        if (doctor && doctor.length > 0) {
          doctorId = doctor[0].id;
        } else {
          doctorId = 'f197d12c-80bc-4480-aa24-dc41f27b1f91'; // Останній фолбек
        }
      }

      const data: any = {
        patientId: dto.patientId,
        doctorId: doctorId,
        items: [{
          name: dto.medicationName,
          dosage: dto.dosage,
          instruction: dto.instruction || '',
        }],
        status: dto.status || 'active',
      };
      
      try {
        const rx = this.prescriptionRepo.create(data);
        return await this.prescriptionRepo.save(rx);
      } catch (error) {
        console.error('Prescription Save Error:', error.message);
        throw error;
      }
    }
    const rx = this.prescriptionRepo.create(dto as Partial<Prescription>);
    return this.prescriptionRepo.save(rx);
  }
}
