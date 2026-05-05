import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ nullable: true })
  userId: string;

  @Column()
  action: string;

  @Column()
  entity: string;

  @Column({ type: 'jsonb', default: '{}' })
  payload: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
