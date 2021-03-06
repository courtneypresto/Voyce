//
//  Card.swift
//  Voyce
//
//  Created by Jordan Ghidossi on 2/10/20.
//  Copyright © 2020 QEDev. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class Card: UIView
{
    @IBOutlet var card: UIView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var vibeButton: UIButton!
    @IBOutlet var numVibes: UILabel!
    @IBOutlet var profileButton: UIButton!
    
    @IBOutlet var postText: UILabel!
    @IBOutlet var postImage: UIImageView!
    @IBOutlet var postVideo: VideoPlayerView!
    @IBOutlet var videoPausedView: UIView!
    
    var user: User?
    var post: Post?
    
    // For using Card in Swift
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        commonInit()
    }
    
    // For using Card in InterfaceBuilder
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit()
    {
        Bundle.main.loadNibNamed("Card", owner: self, options: nil)
        addSubview(card)
        card.frame = self.bounds
        card.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        // Set border color and size of Card
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.init(red: 170/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1.0).cgColor
        card.layer.cornerRadius = 50
        postImage.layer.cornerRadius = 50
        
        layoutIfNeeded()
    }
    
    public func loadPost(feed: FeedViewController, first: Bool) {
        let index = DatabaseManager.shared.index
        DatabaseManager.shared.index += 1
        
        DatabaseManager.shared.db.collection("posts").order(by: "vibes", descending: true).getDocuments() { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                if let document = querySnapshot?.documents[safe: index] {
                    let data = document.data()
                    let postID = document.documentID
                    let userID = data["userID"] as! String
                    
                    DatabaseManager.shared.db.collection("postsSeen").document(postID).getDocument() { document, error in
                        if let document = document, document.exists {
                            let posts = document.data()!["posts"] as! [String]
                            if (posts.contains(userID)) {
                                self.loadPost(feed: feed, first: first)
                                    return
                                    }
                                } else if DatabaseManager.shared.sharedUser.userID == userID {
                            self.loadPost(feed: feed, first: first)
                            return
                        }
                        let date = data["date"] as! String
                        let postType = data["postType"] as! String
                        let content = data["content"] as! String
                        let vibes = data["vibes"] as! Int
                        let caption = data["caption"] as! String
                            
                        let post = Post(pid: postID, userID: userID, date: date, postType: postType, content: content, vibes: vibes, caption: caption)
                        self.addPost(post: post)
                        
                        if first {
                            DatabaseManager.shared.loadComments(postID: postID)
                            self.playVideo()
                            feed.addCard(first: false)
                        }
                        feed.view.insertSubview(self, at: feed.view.subviews.count - (first ? 0 : 1))
                    }
                }
            }
        }
    }
    
    /// Populate Card with associated information
    private func addPost(post: Post) {
        self.post = post
        card.backgroundColor = UIColor(named: "Dark Red")
        numVibes.text = String(post.vibes)
        vibeButton.setImage(randomEmoji(), for: .normal)
    
        let date = Date();
        /// Get post date as formatted string.
        let dateString = date.dateAsString(postDate: post.date)
        /// Cmvert original post format to time format.
        let postTime = date.convertToTimeFormat(postDate: post.date)
        /// Get time since post.
        let timeSincePost = date.timeSincePost(timeAgo: postTime)
        /// Set text.
        let dateLabelText = timeSincePost == "" ? dateString : timeSincePost
        dateLabel.text = dateLabelText
        
        getPosterInfo(userID: post.userID)
        
        switch post.postType {
        case "text":
            postText.isHidden = false
            postText.text = post.content
        case "image":
            postImage.isHidden = false
            let url = URL(string: post.content)
            if url != nil {
                let data = try? Data(contentsOf: url!)
                self.postImage.image = UIImage(data: data!)
            }
        case "video":
            postVideo.isHidden = false
            let url = URL(string: post.content)
            if url != nil {
                let player = AVPlayer(url: url!)
                postVideo.player = player
            }
        default:
            print("Error: Unknown Post Type for \(post.postID)")
        }
    }
    
    private func getPosterInfo(userID: String) {
        DatabaseManager.shared.db.collection("users").document(userID).getDocument() { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let userID = document.documentID
                let name = data!["name"] as! String
                let username = data!["username"] as! String
                let adVibes = data!["adVibes"] as! Int
                let earnedVibes = data!["earnedVibes"] as! Int
                let totalVibes = data!["totalVibes"] as! Int
                let profilePic = data!["profilePic"] as! String
                
                self.user = User(userID: userID, name: name, username: username, adVibes: adVibes, earnedVibes: earnedVibes, totalVibes: totalVibes, profilePic: profilePic)
                print("Profile Image: \(profilePic)")
                self.usernameLabel.text = username
                let profilePicURL = URL(string: profilePic)
                self.profileButton.setImage(self.URLToImg(profilePicURL) ?? UIImage(named: "Profile"), for: .normal)
                self.circularImg(imageView: self.profileButton.imageView)
            } else {
                print("Document does not exist")
            }
        }
    }
    
    /// Action when vibeButton is pressed.
    @IBAction func vibeButtonPressed(_ sender: UIButton) {
        if (DatabaseManager.shared.sharedUser.adVibes > 0) {
            
            DatabaseManager.shared.sharedUser.removeAdVibe()
            // Update vibes in the database
            post?.addVibes(vibes: 1)
            user?.addVibes(totalVibes: 1)
            user?.addVibes(earnedVibes: 1)
            
            // Update UI
            numVibes.text = String(post!.vibes)
            vibeButton.setImage(randomEmoji(), for: .normal)
        }
    }
    
    /// Play video on a video post.
    func playVideo() {
        postVideo.player?.play()
        videoPausedView.isHidden = true
    }
    
    /// Pause video on a video post.
    func pauseVideo() {
        postVideo.player?.pause()
        videoPausedView.isHidden = false
    }
    
    /// Action when profileButton is pressed.
    @IBAction func profileButtonPressed(_ sender: UIButton) {
        
    }
    
    /// Pause video when postVideo is pressed.
    @IBAction func videoPressed(_ sender: UITapGestureRecognizer) {
        pauseVideo()
    }
    
    /// Play video when postVideo is pressed.
    @IBAction func videoPausedPressed(_ sender: UITapGestureRecognizer) {
        playVideo()
    }
    
    /// Returns a random emoji as UIImage.
    public func randomEmoji() -> UIImage!
    {
        var emojiArray = [String]()
        emojiArray.append("art-and-design")
        emojiArray.append("avocado")
        emojiArray.append("birthday-cake")
        emojiArray.append("bread")
        emojiArray.append("cake")
        emojiArray.append("crown")
        emojiArray.append("crowns")
        emojiArray.append("dog")
        emojiArray.append("eye-mask")
        emojiArray.append("falling-star")
        emojiArray.append("fan")
        emojiArray.append("fireworks")
        emojiArray.append("fort")
        emojiArray.append("gems")
        emojiArray.append("hat")
        emojiArray.append("hearts")
        emojiArray.append("ice-cream")
        emojiArray.append("icecream")
        emojiArray.append("idea")
        emojiArray.append("kissing")
        emojiArray.append("lips")
        emojiArray.append("love-letter")
        emojiArray.append("money-1")
        emojiArray.append("money-2")
        emojiArray.append("money")
        emojiArray.append("orchid")
        emojiArray.append("paint-palette")
        emojiArray.append("palette")
        emojiArray.append("party")
        emojiArray.append("phsyics")
        emojiArray.append("pizza")
        emojiArray.append("plastic-cup")
        emojiArray.append("rainbow")
        emojiArray.append("rose-1")
        emojiArray.append("rose-2")
        emojiArray.append("rose")
        emojiArray.append("shirt")
        emojiArray.append("space")
        emojiArray.append("spark")
        emojiArray.append("stars")
        emojiArray.append("strawberry")
        emojiArray.append("sun")
        emojiArray.append("thumbs-up")
        emojiArray.append("venus-de-milo")
        emojiArray.append("yin-yang")
        let randomNumber = Int.random(in: 0..<45)
        return UIImage(named:emojiArray[randomNumber])
    }
    
    func URLToImg(_ url: URL?) -> UIImage?
    {
        guard let imageURL = url else
        {
            return nil
        }
        let data = try? Data(contentsOf: imageURL)
        return UIImage(data: data!)
    }
    
    /// Changes the shape of each profile image into a circle.
    func circularImg(imageView: UIImageView?)
    {
        imageView?.layer.cornerRadius = (imageView?.frame.height ?? 50.0) / 2.0
    }
}
