import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, JoinColumn,
} from 'typeorm';
import { Patient } from '../../patients/entities/patient.entity';
import { Doctor } from '../../doctors/entities/doctor.entity';

@Entity('medical_records')
export class MedicalRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  patientId: string;

  @Column()
  doctorId: string;

  @Column({ nullable: true })
  appointmentId: string;

  @ManyToOne(() => Patient, (p) => p.medicalRecords)
  @JoinColumn({ name: 'patientId' })
  patient: Patient;

  @ManyToOne(() => Doctor)
  @JoinColumn({ name: 'doctorId' })
  doctor: Doctor;

  @Column({ nullable: true })
  diagnosis: string;

  @Column({ type: 'jsonb', default: '{}' })
  notes: Record<string, any>;

  @Column({ nullable: true })
  bloodPressure: string;

  @Column({ type: 'int', nullable: true })
  heartRate: number;

  @Column({ type: 'decimal', precision: 4, scale: 1, nullable: true })
  temperature: number;

  @Column({ type: 'decimal', precision: 5, scale: 1, nullable: true })
  weight: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
