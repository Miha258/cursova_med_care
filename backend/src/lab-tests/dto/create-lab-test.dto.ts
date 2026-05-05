import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { LabTestStatus } from '../entities/lab-test.entity';

export class CreateLabTestDto {
  @ApiProperty()
  @IsString() @IsNotEmpty()
  patientId: string;

  @ApiProperty()
  @IsString() @IsNotEmpty()
  testName: string;

  @ApiPropertyOptional()
  @IsOptional() @IsString()
  result?: string;

  @ApiPropertyOptional({ enum: LabTestStatus })
  @IsOptional() @IsEnum(LabTestStatus)
  status?: LabTestStatus;

  @ApiPropertyOptional()
  @IsOptional() @IsString()
  notes?: string;
}
