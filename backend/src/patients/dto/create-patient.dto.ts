import { IsString, IsOptional, IsDateString, IsArray } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreatePatientDto {
  @ApiProperty({ example: 'Олексій' })
  @IsString()
  firstName: string;

  @ApiProperty({ example: 'Петренко' })
  @IsString()
  lastName: string;

  @ApiPropertyOptional({ example: 'Іванович' })
  @IsOptional()
  @IsString()
  middleName?: string;

  @ApiProperty({ example: '1978-03-15' })
  @IsDateString()
  birthDate: string;

  @ApiPropertyOptional({ example: '+380671234567' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: 'patient@email.com' })
  @IsOptional()
  @IsString()
  email?: string;

  @ApiPropertyOptional({ example: 'UA-2024-8847261' })
  @IsOptional()
  @IsString()
  insuranceNo?: string;

  @ApiPropertyOptional({ example: 'II' })
  @IsOptional()
  @IsString()
  bloodGroup?: string;

  @ApiPropertyOptional({ example: '+' })
  @IsOptional()
  @IsString()
  rhFactor?: string;

  @ApiPropertyOptional({ example: ['Пеніцилін'] })
  @IsOptional()
  @IsArray()
  allergies?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  primaryDoctorId?: string;
}
