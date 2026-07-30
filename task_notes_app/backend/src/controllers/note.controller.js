const noteService = require('../services/note.service');
const { sendResponse } = require('../utils/responseHandler');

const getNotes = async (req, res, next) => {
  try {
    const { notes, meta } = await noteService.getNotes(req.user.id, req.query);
    return sendResponse(res, 200, 'Notes retrieved successfully', notes, meta);
  } catch (error) {
    next(error);
  }
};

const getNoteById = async (req, res, next) => {
  try {
    const note = await noteService.getNoteById(req.params.id, req.user.id);
    return sendResponse(res, 200, 'Note retrieved successfully', note);
  } catch (error) {
    next(error);
  }
};

const createNote = async (req, res, next) => {
  try {
    const note = await noteService.createNote(req.user.id, req.body);
    return sendResponse(res, 201, 'Note created successfully', note);
  } catch (error) {
    next(error);
  }
};

const updateNote = async (req, res, next) => {
  try {
    const note = await noteService.updateNote(req.params.id, req.user.id, req.body);
    return sendResponse(res, 200, 'Note updated successfully', note);
  } catch (error) {
    next(error);
  }
};

const deleteNote = async (req, res, next) => {
  try {
    await noteService.deleteNote(req.params.id, req.user.id);
    return sendResponse(res, 204, 'Note deleted successfully');
  } catch (error) {
    next(error);
  }
};

const toggleArchive = async (req, res, next) => {
  try {
    const note = await noteService.setArchived(req.params.id, req.user.id, req.body.isArchived);
    return sendResponse(res, 200, 'Note archive status updated', note);
  } catch (error) {
    next(error);
  }
};

const togglePin = async (req, res, next) => {
  try {
    const note = await noteService.setPinned(req.params.id, req.user.id, req.body.isPinned);
    return sendResponse(res, 200, 'Note pin status updated', note);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getNotes,
  getNoteById,
  createNote,
  updateNote,
  deleteNote,
  toggleArchive,
  togglePin
};
