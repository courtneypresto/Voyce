//
//  UserManager.swift
//  Voyce
//
//  Created by Quinn Ellis on 9/19/19.
//  Copyright © 2019 QEDev. All rights reserved.
//

import Foundation

class UserManager {

  static let shared = UserManager()

  var posts: [Post] = []

  public func initWithPlaceholderPosts() {
    posts.append(Post(text: "First Post", username: "quinn", likeCount: 19))
    posts.append(Post(text: "Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post Long post ", username: "quinn", likeCount: 119))
    posts.append(Post(text: "quinn", username: "quinn", likeCount: 1119))
  }

}
