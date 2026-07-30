const { v4: uuidv4 } = require('uuid');
const NoteRepository = require('../repositories/note.repository');
const AppError = require('../utils/AppError');
const { pool } = require('../config/database');

class NoteService {
  constructor() {
    this.noteRepo = new NoteRepository(pool);
  }

  async getNotes(userId, queryParams) {
    const page = parseInt(queryParams.page || '1', 10);
    const limit = parseInt(queryParams.limit || '20', 10);
    const offset = (page - 1) * limit;

    const notes = await this.noteRepo.findByUser(userId, {
      ...queryParams,
      limit,
      offset,
      isArchived: queryParams.is_archived === 'true'
    });

    const total = await this.noteRepo.countByUser(userId, {
      isArchived: queryParams.is_archived === 'true'
    });

    return { notes, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
  }

  async getNoteById(id, userId) {
    const note = await this.noteRepo.findById(id, userId);
    if (!note) {
      throw new AppError('Note not found.', 404, 'NOTE_NOT_FOUND');
    }
    return note;
  }

  async createNote(userId, noteData) {
    const id = noteData.id || uuidv4();
    return this.noteRepo.create({
      id,
      userId,
      ...noteData
    });
  }

  async updateNote(id, userId, updateData) {
    try {
      if (!updateData.version) {
        throw new AppError('Version is required for optimistic concurrency control.', 400, 'VERSION_MISSING');
      }
      const updatedNote = await this.noteRepo.updateWithVersionCheck(id, userId, updateData, updateData.version);
      if (!updatedNote) {
        throw new AppError('Note not found.', 404, 'NOTE_NOT_FOUND');
      }
      return updatedNote;
    } catch (error) {
      if (error.message === 'VERSION_CONFLICT') {
        const serverRecord = await this.noteRepo.findById(id, userId);
        throw new AppError(
          'Conflict detected. The note was modified on another device.',
          409,
          'CONCURRENCY_CONFLICT',
          { serverRecord }
        );
      }
      throw error;
    }
  }

  async deleteNote(id, userId) {
    const deleted = await this.noteRepo.softDelete(id, userId);
    if (!deleted) {
      throw new AppError('Note not found or already deleted.', 404, 'NOTE_NOT_FOUND');
    }
    return true;
  }

  async setArchived(id, userId, isArchived) {
    const updated = await this.noteRepo.setArchived(id, userId, isArchived);
    if (!updated) {
      throw new AppError('Note not found.', 404, 'NOTE_NOT_FOUND');
    }
    return this.noteRepo.findById(id, userId);
  }

  async setPinned(id, userId, isPinned) {
    const updated = await this.noteRepo.setPinned(id, userId, isPinned);
    if (!updated) {
      throw new AppError('Note not found.', 404, 'NOTE_NOT_FOUND');
    }
    return this.noteRepo.findById(id, userId);
  }
}

module.exports = new NoteService();
