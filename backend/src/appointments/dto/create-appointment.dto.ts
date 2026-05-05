import { IsString, IsDateString, IsOptional, IsEnum, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AppointmentReason } from '../entities/appointment.entity';

export class CreateAppointmentDto {
  @ApiProperty()
  @IsString()
  patientId: string;

  @ApiProperty()
  @IsString()
  doctorId: string;

  @ApiProperty({ example: '2026-12-07T09:00:00.000Z' })
  @IsDateString()
  startTime: string;

  @ApiProperty({ example: '2026-12-07T09:30:00.000Z' })
  @IsDateString()
  endTime: string;

  @ApiPropertyOptional({ enum: AppointmentReason })
  @IsOptional()
  @IsEnum(AppointmentReason)
  reason?: AppointmentReason;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  admissionRequired?: boolean;
}
