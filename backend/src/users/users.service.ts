import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private repo: Repository<User>) {}

  findByEmail(email: string) {
    return this.repo.findOne({ where: { email } });
  }

  findById(id: string) {
    return this.repo.findOne({ where: { id } });
  }

  async create(data: Partial<User>) {
    const hashed = await bcrypt.hash(data.password, 12);
    const user = this.repo.create({ ...data, password: hashed });
    return this.repo.save(user);
  }

  findAll() {
    return this.repo.find({ select: ['id', 'email', 'role', 'firstName', 'lastName', 'createdAt'] });
  }
}
