import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Patient } from '../../patients/entities/patient.entity';

export enum LabTestStatus {
  PENDING = 'pending',
  NORMAL = 'normal',
  ABNORMAL = 'abnormal',
}

@Entity('lab_tests')
export class LabTest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  patientId: string;

  @ManyToOne(() => Patient)
  @JoinColumn({ name: 'patientId' })
  patient: Patient;

  @Column()
  testName: string;

  @Column({ nullable: true })
  result: string;

  @Column({ type: 'enum', enum: LabTestStatus, default: LabTestStatus.PENDING })
  status: LabTestStatus;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;
}
