import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/project_model.dart';
import '../../core/services/draft_service.dart';

class EditorState {
  final ProjectModel project;
  final bool canUndo;
  final bool canRedo;

  EditorState({required this.project, this.canUndo = false, this.canRedo = false});
}

class EditorCubit extends Cubit<EditorState> {
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  EditorCubit(ProjectModel initialProject) : super(EditorState(project: initialProject));

  ProjectModel get project => state.project;

  void _pushHistoryAndEmit(ProjectModel newProject) {
    _undoStack.add(state.project.toJsonString());
    _redoStack.clear();
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    emit(EditorState(project: newProject, canUndo: _undoStack.isNotEmpty, canRedo: false));
    _autoSave();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(state.project.toJsonString());
    final prev = ProjectModel.fromJsonString(_undoStack.removeLast());
    emit(EditorState(project: prev, canUndo: _undoStack.isNotEmpty, canRedo: true));
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(state.project.toJsonString());
    final next = ProjectModel.fromJsonString(_redoStack.removeLast());
    emit(EditorState(project: next, canUndo: true, canRedo: _redoStack.isNotEmpty));
  }

  void addClip(ClipModel clip) {
    final p = state.project.copy();
    p.clips.add(clip);
    _pushHistoryAndEmit(p);
  }

  void removeClip(String clipId) {
    final p = state.project.copy();
    p.clips.removeWhere((c) => c.id == clipId);
    _pushHistoryAndEmit(p);
  }

  void updateClip(String clipId, void Function(ClipModel) update) {
    final p = state.project.copy();
    final clip = p.clips.firstWhere((c) => c.id == clipId);
    update(clip);
    _pushHistoryAndEmit(p);
  }

  void addText(TextOverlayModel text) {
    final p = state.project.copy();
    p.texts.add(text);
    _pushHistoryAndEmit(p);
  }

  void removeText(String id) {
    final p = state.project.copy();
    p.texts.removeWhere((t) => t.id == id);
    _pushHistoryAndEmit(p);
  }

  void addAudioTrack(AudioTrackModel track) {
    final p = state.project.copy();
    p.audioTracks.add(track);
    _pushHistoryAndEmit(p);
  }

  void removeAudioTrack(String id) {
    final p = state.project.copy();
    p.audioTracks.removeWhere((a) => a.id == id);
    _pushHistoryAndEmit(p);
  }

  void setMuteOriginal(bool value) {
    final p = state.project.copy();
    p.muteOriginal = value;
    _pushHistoryAndEmit(p);
  }

  void addSticker(StickerOverlayModel sticker) {
    final p = state.project.copy();
    p.stickers.add(sticker);
    _pushHistoryAndEmit(p);
  }

  void removeSticker(String id) {
    final p = state.project.copy();
    p.stickers.removeWhere((s) => s.id == id);
    _pushHistoryAndEmit(p);
  }

  void setPipOverlay(PipOverlayModel? pip) {
    final p = state.project.copy();
    p.pipOverlay = pip;
    _pushHistoryAndEmit(p);
  }

  void setBackground(BackgroundModel bg) {
    final p = state.project.copy();
    p.background = bg;
    _pushHistoryAndEmit(p);
  }

  Future<void> _autoSave() async {
    await DraftService.save(state.project);
  }

  Future<void> saveNow() async {
    await DraftService.save(state.project);
  }
}
