//
//  WebViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 04/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    var url: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        let webpageURL = URL(string: url)
        let request = URLRequest(url: webpageURL!)
        
        webView.loadRequest(request)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}

extension WebViewController : UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loading.stopAnimating()
    }
}
