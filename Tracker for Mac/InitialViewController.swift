//
//  InitialViewController.swift
//  Tracker for Mac
//
//  Created by Simon Raboczi on 16/05/2016.
//  Copyright © 2016 Simon Raboczi. All rights reserved.
//

import Cocoa
import GameKit

class InitialViewController: NSViewController, InitialViewControllerProtocol {
    
    // MARK: Interface builder
    
    @IBOutlet var localPlayerImage: NSImageView!
    @IBOutlet var localPlayerAlias: NSTextFieldCell!
    
    @IBOutlet var newRealTimeMatchButton: NSButton!
    @IBOutlet var newHostedMatchButton: NSButton!
    @IBOutlet var newTurnBasedMatchButton: NSButton!
    
    @IBAction func newRealTimeMatchButtonPressed(button: NSButton) { newRealTimeMatch() }
    @IBAction func newHostedMatchButtonPressed(button: NSButton) { newHostedMatch() }
    @IBAction func newTurnBasedMatchButtonPressed(button: NSButton) { newTurnBasedMatch() }
    
    @IBOutlet var playButton: NSButton!
    @IBOutlet var deleteButton: NSButton!
    @IBOutlet var endButton: NSButton!
    @IBOutlet var resignButton: NSButton!
    @IBOutlet var rematchButton: NSButton!
    @IBOutlet var listButton: NSButton!
    
    @IBAction func playButtonPressed(button: NSButton) { play() }
    @IBAction func deleteButtonPressed(button: NSButton) { delete() }
    @IBAction func endButtonPressed(button: NSButton) { end() }
    @IBAction func resignButtonPressed(button: NSButton) { resign() }
    @IBAction func rematchButtonPressed(button: NSButton) { rematch() }
    @IBAction func listButtonPressed(button: NSButton) { list() }
    
    // MARK: InitialViewControllerProtocol
    
    var turnBasedMatch: GKTurnBasedMatch? {
        didSet {
            playButton.enabled = (turnBasedMatch != nil)
        }
    }
    
    var localPlayerAliasText: String {
        get { return localPlayerAlias.stringValue }
        set { localPlayerAlias.stringValue = newValue }
    }
    
    var localPlayerImageImage: NSImage? {
        get { return localPlayerImage.image }
        set { localPlayerImage.image = newValue }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newRealTimeMatchButton.enabled = false
        newHostedMatchButton.enabled = false
        newTurnBasedMatchButton.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerAuthenticationDidChangeNotification), name: GKPlayerAuthenticationDidChangeNotificationName, object: nil)
        
        localPlayer.unregisterAllListeners()
        localPlayer.registerListener(self)
        localPlayer.authenticateHandler = authenticate
    }
    
    @objc private func playerAuthenticationDidChangeNotification(sender: AnyObject) {
        debugPrint("Local player authentication changed, now \(localPlayer.authenticated)")
        
        newRealTimeMatchButton.enabled = localPlayer.authenticated
        newHostedMatchButton.enabled = localPlayer.authenticated
        newTurnBasedMatchButton.enabled = localPlayer.authenticated
        turnBasedMatch = nil
        
        if localPlayer.authenticated {
            debugPrint("Local player has been authenticated: \(localPlayer)")
            localPlayerAliasText = localPlayer.alias ?? ""
            
            localPlayer.loadPhotoForSize(GKPhotoSizeSmall) {
                (image, error) in
                if let image = image {
                    debugPrint("Loaded local player photo \(image)")
                    self.localPlayerImageImage = image
                }
                else if let error = error {
                    self.showError(error, message: "Unable to load your photo")
                }
            }
            
        } else {
            debugPrint("Local player is not authenticated: \(localPlayer)")
            localPlayerAliasText = "Not authenticated"
            localPlayerImageImage = nil
        }
    }
    
    func dismissViewController() {
        let _ = self.presentedViewControllers?.map { self.dismissViewController($0) }
    }
    
    func showError(error : NSError, message : String) {
        let alert = NSAlert(error: error);
        let response = alert.runModal()
        switch response {
        case NSModalResponseStop: break
        case NSModalResponseAbort: break
        case NSModalResponseContinue: break
        default: debugPrint("Unhandled NSModalResponse code: \(response)")
        }
    }
    
    // MARK: GKMatchmakerViewControllerDelegate (subprotocol of InitialViewControllerProtocol)
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindMatch match: GKMatch) {
        debugPrint("Found match \(match)")
        dismissViewController()
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindHostedPlayers players: [GKPlayer]) {
        debugPrint("Found hosted players \(players)")
    }
    
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController) {
        debugPrint("Canceled")
        dismissViewController()
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFailWithError error: NSError) {
        debugPrint("Failed with error \(error)")
        showError(error, message: "Matchmaking failed")
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, hostedPlayerDidAccept player: GKPlayer) {
        debugPrint("Accepted by player \(player)")
    }
    
    // MARK: GKTurnBasedMatchmakerViewControllerDelegate (subprotocol of InitialViewControllerProtocol)
    
    func turnBasedMatchmakerViewControllerWasCancelled(viewController: GKTurnBasedMatchmakerViewController) {
        debugPrint("Canceled matchmaking")
        dismissViewController()
    }
    
    func turnBasedMatchmakerViewController(viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: NSError) {
        debugPrint("Failed to find match \(error)")
        showError(error, message: "Matchmaking failed")
    }
    
    // MARK: GKChallengeListener (subprotocol of GKLocalPlayerListener)
    
    func player(player: GKPlayer, wantsToPlayChallenge challenge: GKChallenge) {
        debugPrint("Player \(player) wants to play challenge \(challenge)")
    }
    
    // Called when a player has received a challenge, triggered by a push notification from the server. Received only while the game is running.
    // player: The player who received the challenge
    // challenge: The challenge which was received
    func player(player: GKPlayer, didReceiveChallenge challenge: GKChallenge) {
        debugPrint("Player \(player) received challenge \(challenge)")
    }
    
    // Called when a player has completed a challenge, triggered while the game is running, or when the user has tapped a challenge notification banner while outside of the game.
    // player: The player who completed the challenge
    // challenge: The challenge which the player completed
    // friendPlayer: The friend who sent the challenge originally
    func player(player: GKPlayer, didCompleteChallenge challenge: GKChallenge, issuedByFriend friendPlayer: GKPlayer) {
        debugPrint("Player \(player) completed challenge \(challenge) issued by friend \(friendPlayer)")
    }
    
    // Called when a player's friend has completed a challenge which the player sent to that friend. Triggered while the game is running, or when the user has tapped a challenge notification banner while outside of the game.
    // player: The player who sent the challenge originally
    // challenge: The challenge which the player created and sent
    // friendPlayer: The friend who completed the challenge
    func player(player: GKPlayer, issuedChallengeWasCompleted challenge: GKChallenge, byFriend friendPlayer: GKPlayer) {
        debugPrint("Player \(player) completed issued challenge \(challenge) by friend \(friendPlayer)")
    }
    
    // MARK: GKInviteEventListener (subprotocol of GKLocalPlayerListener)
    
    func player(player: GKPlayer, didAcceptInvite invite: GKInvite) {
        debugPrint("Player \(player) accepted invitation \(invite)")
    }
    
    // didRequestMatchWithRecipients: gets called when the player chooses to play with another player from Game Center and it launches the game to start matchmaking
    func player(player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        debugPrint("Player \(player) requested match with \(recipientPlayers)")
    }
    
    // MARK: GKSavedGameListener (subprotocol of GKLocalPlayerListener)
    
    func player(player: GKPlayer, didModifySavedGame savedGame: GKSavedGame) {
        debugPrint("Player \(player) modified saved game \(savedGame)")
    }
    
    // Called when a conflict has arisen between different versions of the same saved game. This can happen when multiple devices write to the same saved game while one or more is offline. The application should determine the correct data to use, then call resolveConflictingSavedGames:withData:completionHandler:. This may require data merging or asking the user.
    func player(player: GKPlayer, hasConflictingSavedGames savedGames: [GKSavedGame]) {
        debugPrint("Player \(player) has conflicting saved games \(savedGames)")
    }
    
    // MARK: GKTurnBasedEventListener (subprotocol of GKLocalPlayerListener)
    
    func player(player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {
        debugPrint("Requested match with \(playersToInvite)")
    }
    
    // called when it becomes this player's turn.  It also gets called under the following conditions:
    //      the player's turn has a timeout and it is about to expire.
    //      the player accepts an invite from another player.
    // when the game is running it will additionally recieve turn events for the following:
    //      turn was passed to another player
    //      another player saved the match data
    // Because of this the app needs to be prepared to handle this even while the player is taking a turn in an existing match.  The boolean indicates whether this event launched or brought to foreground the app.
    func player(player: GKPlayer, receivedTurnEventForMatch match: GKTurnBasedMatch, didBecomeActive: Bool) {
        debugPrint("Player \(player) received turn event for match \(match),Y becoming active: \(didBecomeActive)")
        
        self.turnBasedMatch = match
    }
    
    // called when the match has ended.
    func player(player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        debugPrint("Player \(player) ended match \(match)")
    }
    
    // this is called when a player receives an exchange request from another player.
    func player(player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, forMatch match: GKTurnBasedMatch) {
        debugPrint("Player \(player) requested exchange \(exchange) for match \(match)")
    }
    
    // this is called when an exchange is canceled by the sender.
    func player(player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, forMatch match: GKTurnBasedMatch) {
        debugPrint("Player \(player) canceled exchange \(exchange) for match \(match)")
    }
    
    // called when all players either respond or timeout responding to this request.  This is sent to both the turn holder and the initiator of the exchange
    func player(player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, forMatch match: GKTurnBasedMatch) {
        debugPrint("Player \(player) replied \(replies) for completed exchange \(exchange) for match \(match)")
    }
    
    // Called when a player chooses to quit a match and that player has the current turn.  The developer should call participantQuitInTurnWithOutcome:nextParticipants:turnTimeout:matchData:completionHandler: on the match passing in appropriate values.  They can also update matchOutcome for other players as appropriate.
    func player(player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        debugPrint("Player \(player) wants to quit match \(match)")
    }
}