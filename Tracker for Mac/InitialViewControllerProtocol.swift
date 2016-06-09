//
//  InitialViewControllerProtocol.swift
//  Tracker
//
//  Created by Simon Raboczi on 10/05/2016.
//  Copyright © 2016 Simon Raboczi. All rights reserved.
//

import GameKit

protocol InitialViewControllerProtocol: GKLocalPlayerListener, GKMatchmakerViewControllerDelegate, GKTurnBasedMatchmakerViewControllerDelegate {
    
    associatedtype VC     // NSViewController (MacOS) or UIViewController (iOS,tvOS)
    associatedtype IMAGE  // NSImage (MacOS) or UIImage (iOS,tvOS)
    
    // MARK:
    var turnBasedMatch: GKTurnBasedMatch? { get set }
    var localPlayerAliasText: String { get set }
    var localPlayerImageImage: IMAGE? { get set }
    
    func presentViewControllerAsModalWindow(viewController: VC)
    func dismissViewController()
    func showError(error : NSError, message : String)
    
    var localPlayer: GKLocalPlayer { get }
    func authenticate(authenticationViewController: VC?, error: NSError?)
    func viewDidLoad()
}

extension InitialViewControllerProtocol {
    
    var localPlayer: GKLocalPlayer {
        get {
            return GKLocalPlayer.localPlayer()
        }
    }
    
    // MARK: GKLocalPlayer
    
    func authenticate(authenticationViewController: VC?, error: NSError?) {
        
        if let authenticationViewController = authenticationViewController {
            debugPrint("Local player has not been authenticated; offering sign-in")
            presentViewControllerAsModalWindow(authenticationViewController)
        }
        
        if localPlayer.authenticated {
            debugPrint("Local player has been authenticated: \(localPlayer)")
            localPlayerAliasText = localPlayer.alias ?? ""
            
            localPlayer.loadPhotoForSize(GKPhotoSizeSmall) {
                (image, error) in
                if let image = image {
                    debugPrint("Loaded local player photo \(image)")
                    self.localPlayerImageImage = image as? IMAGE
                }
                else if let error = error {
                    self.showError(error, message: "Unable to load your photo")
                }
            }            
        }
        else {
            debugPrint("Local player has not been authenticated, so Game Center should be disabled")
            self.localPlayerAliasText = "Not authenticated"
            self.localPlayerImageImage = nil
        }
    }
        
    // MARK: Button handlers
    
    func newRealTimeMatch() {
        debugPrint("New real-time match")
        
        let matchRequest = newMatchRequest(.PeerToPeer)
        if let matchmakerViewController = GKMatchmakerViewController(matchRequest: matchRequest) {
            matchmakerViewController.matchmakerDelegate = self
            self.presentViewControllerAsModalWindow(matchmakerViewController as! VC)
        }
        else {
            debugPrint("Matchmaking failed because GKMatchmakerViewController creation failed")
        }
    }
    
    func newHostedMatch() {
        debugPrint("New hosted match")
        
        let matchRequest = newMatchRequest(.Hosted)
        if let matchmakerViewController = GKMatchmakerViewController(matchRequest: matchRequest) {
            matchmakerViewController.hosted = true
            matchmakerViewController.matchmakerDelegate = self //MatchmakerViewControllerDelegate(t: self)
            self.presentViewControllerAsModalWindow(matchmakerViewController as! VC)
        }
        else {
            debugPrint("Matchmaking failed because GKMatchmakerViewController creation failed")
        }
    }
    
    func newTurnBasedMatch() {
        debugPrint("New turn-based match")
        
        let matchRequest = newMatchRequest(.TurnBased)
        let matchmakerViewController = GKTurnBasedMatchmakerViewController(matchRequest: matchRequest)
        matchmakerViewController.turnBasedMatchmakerDelegate = self
        self.presentViewControllerAsModalWindow(matchmakerViewController as! VC)
    }
    
    private func newMatchRequest(matchType: GKMatchType) -> GKMatchRequest
    {
        let matchRequest = GKMatchRequest()
        matchRequest.minPlayers = 2
        matchRequest.maxPlayers = GKMatchRequest.maxPlayersAllowedForMatchOfType(matchType)
        matchRequest.defaultNumberOfPlayers = 2
        matchRequest.inviteMessage = "Would you like to play a game?"
        matchRequest.recipients = []
        
        func handleRecipientResponse(recipient: GKPlayer, response: GKInviteRecipientResponse) {
            debugPrint("Response from \(recipient) is \(response)")
        }
        
        matchRequest.recipientResponseHandler = handleRecipientResponse
        
        return matchRequest
    }
    
    func play() {
        debugPrint("Play button pressed")
        if let match = turnBasedMatch {
            debugPrint("Play a turn in \(match)")
            guard let me = match.currentParticipant else { fatalError("No current participant") }
            guard let us = match.participants else { fatalError("No participants") }
            
            func followingParticipants(participants: [GKTurnBasedParticipant], following: GKTurnBasedParticipant) -> [GKTurnBasedParticipant] {
                return participants
            }
            
            let nextParticipants = followingParticipants(us, following: me)
            guard let matchData = "Dummy".dataUsingEncoding(NSUTF8StringEncoding) else {
                fatalError("Couldn't create hardcoded constant buffer")
            }
            match.endTurnWithNextParticipants(nextParticipants, turnTimeout: 300 /* seconds */, matchData: matchData) {
                error in
                debugPrint("Ended turn")
            }
        } else {
            debugPrint("Tried to play a turn, but there is no match")
        }
    }
    
    func delete() {
        debugPrint("Delete button pressed")
        if let match = turnBasedMatch {
            match.removeWithCompletionHandler {
                error in
                if let error = error {
                    debugPrint("Unable to delete match \(error)")
                } else {
                    debugPrint("Deleted match")
                }
            }
        } else {
            debugPrint("No match to delete")
        }
    }
    
    func end() {
        debugPrint("End button pressed")
    }
    
    func resign() {
        debugPrint("Resign button pressed")
    }
    
    func rematch() {
        debugPrint("Rematch button pressed")
        if let match = turnBasedMatch {
            match.rematchWithCompletionHandler {
                (turnBasedRematch, error) in
                if let error = error {
                    self.showError(error, message: "Unable to rematch")
                }
                if let rematch = turnBasedRematch {
                    debugPrint("Rematch \(rematch)")
                }
            }
        }
    }
    
    func list() {
        debugPrint("List button pressed");
        GKTurnBasedMatch.loadMatchesWithCompletionHandler {
            (turnBasedMatches, error) in
            if let error = error {
                self.showError(error, message: "Couldn't list matches")
            }
            if let matches = turnBasedMatches {
                debugPrint("Matches list \(matches)")
            } else {
                debugPrint("No matches list")
            }
        }
    }
}