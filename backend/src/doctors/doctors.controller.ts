import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { DoctorsService } from './doctors.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Doctor } from './entities/doctor.entity';

@ApiTags('doctors')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('doctors')
export class DoctorsController {
  constructor(private service: DoctorsService) {}

  @Get()
  @ApiQuery({ name: 'specialization', required: false })
  findAll(@Query('specialization') spec?: string) {
    return this.service.findAll(spec);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Post()
  create(@Body() dto: Partial<Doctor>) {
    return this.service.create(dto);
  }
}
