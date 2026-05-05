import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  UpdateDateColumn, ManyToOne, OneToMany, JoinColumn,
} from 'typeorm';
import { Doctor } from '../../doctors/entities/doctor.entity';
import { Appointment } from '../../appointments/entities/appointment.entity';
import { MedicalRecord } from '../../medical-records/entities/medical-record.entity';
import { Prescription } from '../../pharmacy/entities/prescription.entity';
import { Invoice } from '../../finance/entities/invoice.entity';

@Entity('patients')
export class Patient {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @Column({ nullable: true })
  middleName: string;

  @Column({ type: 'date' })
  birthDate: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  email: string;

  @Column({ nullable: true })
  insuranceNo: string;

  @Column({ nullable: true })
  bloodGroup: string;

  @Column({ nullable: true })
  rhFactor: string;

  @Column({ type: 'jsonb', default: '[]' })
  allergies: string[];

  @Column({ nullable: true })
  primaryDoctorId: string;

  @ManyToOne(() => Doctor, { nullable: true, eager: false })
  @JoinColumn({ name: 'primaryDoctorId' })
  primaryDoctor: Doctor;

  @OneToMany(() => Appointment, (a) => a.patient)
  appointments: Appointment[];

  @OneToMany(() => MedicalRecord, (r) => r.patient)
  medicalRecords: MedicalRecord[];

  @OneToMany(() => Prescription, (p) => p.patient)
  prescriptions: Prescription[];

  @OneToMany(() => Invoice, (i) => i.patient)
  invoices: Invoice[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
