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
  async findPrescriptionsByPatient(patientId: string) {
    const list = await this.prescriptionRepo.find({ where: { patientId }, order: { issuedAt: 'DESC' } });
    return list.map(rx => this._flattenPrescription(rx));
  }

  private _flattenPrescription(rx: Prescription) {
    const first = Array.isArray(rx.items) && rx.items.length > 0 ? rx.items[0] : null;
    return {
      id: rx.id,
      patientId: rx.patientId,
      doctorId: rx.doctorId,
      status: rx.status,
      medicationName: first?.name ?? '',
      dosage: first?.dosage ?? '',
      instruction: (first as any)?.instruction ?? '',
      createdAt: rx.createdAt,
    };
  }

  async updatePrescription(id: string, dto: any) {
    const rx = await this.prescriptionRepo.findOne({ where: { id } });
    if (!rx) throw new NotFoundException('Рецепт не знайдено');
    if (dto.medicationName || dto.dosage || dto.instruction) {
      rx.items = [{ name: dto.medicationName ?? rx.items[0]?.name, dosage: dto.dosage ?? rx.items[0]?.dosage, frequency: '', duration: '', ...(dto.instruction ? { instruction: dto.instruction } as any : {}) }];
    }
    if (dto.status) rx.status = dto.status;
    const saved = await this.prescriptionRepo.save(rx);
    return this._flattenPrescription(saved);
  }

  async deletePrescription(id: string) {
    const rx = await this.prescriptionRepo.findOne({ where: { id } });
    if (!rx) throw new NotFoundException('Рецепт не знайдено');
    return this.prescriptionRepo.remove(rx);
  }

  async createPrescription(dto: any) {
    if (dto.medicationName) {
      let doctorId = dto.doctorId;
      
      // Логуємо вхідні дані для діагностики
      console.log(`[PharmacyService] Attempting to create prescription for patient ${dto.patientId}`);

      if (!doctorId) {
        const doctors = await this.prescriptionRepo.query('SELECT id FROM doctors LIMIT 1');
        if (doctors && doctors.length > 0) {
          doctorId = doctors[0].id;
          console.log(`[PharmacyService] No doctorId provided, using fallback from DB: ${doctorId}`);
        } else {
          console.error('[PharmacyService] CRITICAL: No doctors found in database!');
          throw new Error('У системі не знайдено жодного лікаря. Рецепт не може бути створений.');
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
        console.log('[PharmacyService] Final data for save:', JSON.stringify(data));
        const rx = this.prescriptionRepo.create(data);
        const saved = await this.prescriptionRepo.save(rx) as unknown as Prescription;
        return this._flattenPrescription(saved);
      } catch (error) {
        console.error(`[PharmacyService] Save Failed. DoctorId: ${doctorId}, PatientId: ${dto.patientId}`);
        console.error('[PharmacyService] Database Error:', error.message);
        throw error;
      }
    }
    const rx = this.prescriptionRepo.create(dto as Partial<Prescription>);
    return this.prescriptionRepo.save(rx);
  }
}
