//
//  ProblemNote.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import Foundation

// MARK: - Problem Note
struct ProblemNote: Codable, Identifiable {
    let id = UUID()
    let problemId: String // Combination of contestId and index
    let note: String
    let createdAt: Date
    let updatedAt: Date
    
    init(problemId: String, note: String) {
        self.problemId = problemId
        self.note = note
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Problem Review Later
struct ProblemReviewLater: Codable, Identifiable {
    let id = UUID()
    let problemId: String
    let addedAt: Date
    
    init(problemId: String) {
        self.problemId = problemId
        self.addedAt = Date()
    }
}

// MARK: - Solution Gallery
struct ProblemSolution: Codable, Identifiable {
    let id = UUID()
    let problemId: String
    let submissionId: Int
    let code: String
    let language: String
    let savedAt: Date
    let title: String
    let description: String?
    
    init(problemId: String, submissionId: Int, code: String, language: String, title: String, description: String? = nil) {
        self.problemId = problemId
        self.submissionId = submissionId
        self.code = code
        self.language = language
        self.title = title
        self.description = description
        self.savedAt = Date()
    }
}

// MARK: - Problem Data Manager
@MainActor
class ProblemDataManager: ObservableObject {
    static let shared = ProblemDataManager()
    
    @Published var notes: [ProblemNote] = []
    @Published var reviewLaterProblems: [ProblemReviewLater] = []
    @Published var solutions: [ProblemSolution] = []
    
    private let notesKey = "problem_notes"
    private let reviewLaterKey = "review_later_problems"
    private let solutionsKey = "problem_solutions"
    
    private init() {
        loadData()
    }
    
    // MARK: - Notes Management
    func addNote(for problemId: String, note: String) {
        let newNote = ProblemNote(problemId: problemId, note: note)
        notes.append(newNote)
        saveNotes()
    }
    
    func updateNote(_ note: ProblemNote, newText: String) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote = ProblemNote(problemId: note.problemId, note: newText)
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func deleteNote(_ note: ProblemNote) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func getNotes(for problemId: String) -> [ProblemNote] {
        return notes.filter { $0.problemId == problemId }
    }
    
    // MARK: - Review Later Management
    func addToReviewLater(problemId: String) {
        if !isInReviewLater(problemId: problemId) {
            let reviewLater = ProblemReviewLater(problemId: problemId)
            reviewLaterProblems.append(reviewLater)
            saveReviewLater()
        }
    }
    
    func removeFromReviewLater(problemId: String) {
        reviewLaterProblems.removeAll { $0.problemId == problemId }
        saveReviewLater()
    }
    
    func isInReviewLater(problemId: String) -> Bool {
        return reviewLaterProblems.contains { $0.problemId == problemId }
    }
    
    func getReviewLaterProblems() -> [ProblemReviewLater] {
        return reviewLaterProblems.sorted { $0.addedAt > $1.addedAt }
    }
    
    // MARK: - Solutions Management
    func saveSolution(_ solution: ProblemSolution) {
        solutions.append(solution)
        saveSolutions()
    }
    
    func deleteSolution(_ solution: ProblemSolution) {
        solutions.removeAll { $0.id == solution.id }
        saveSolutions()
    }
    
    func getSolutions(for problemId: String) -> [ProblemSolution] {
        return solutions.filter { $0.problemId == problemId }
    }
    
    func getAllSolutions() -> [ProblemSolution] {
        return solutions.sorted { $0.savedAt > $1.savedAt }
    }
    
    // MARK: - Persistence
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func saveReviewLater() {
        if let encoded = try? JSONEncoder().encode(reviewLaterProblems) {
            UserDefaults.standard.set(encoded, forKey: reviewLaterKey)
        }
    }
    
    private func saveSolutions() {
        if let encoded = try? JSONEncoder().encode(solutions) {
            UserDefaults.standard.set(encoded, forKey: solutionsKey)
        }
    }
    
    private func loadData() {
        // Load notes
        if let notesData = UserDefaults.standard.data(forKey: notesKey),
           let decodedNotes = try? JSONDecoder().decode([ProblemNote].self, from: notesData) {
            notes = decodedNotes
        }
        
        // Load review later
        if let reviewLaterData = UserDefaults.standard.data(forKey: reviewLaterKey),
           let decodedReviewLater = try? JSONDecoder().decode([ProblemReviewLater].self, from: reviewLaterData) {
            reviewLaterProblems = decodedReviewLater
        }
        
        // Load solutions
        if let solutionsData = UserDefaults.standard.data(forKey: solutionsKey),
           let decodedSolutions = try? JSONDecoder().decode([ProblemSolution].self, from: solutionsData) {
            solutions = decodedSolutions
        }
    }
}

// MARK: - Extensions
extension CFProblem {
    var problemId: String {
        if let contestId = contestId {
            return "\(contestId)_\(index)"
        }
        return index
    }
} 