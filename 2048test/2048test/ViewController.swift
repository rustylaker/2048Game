//
//  ViewController.swift
//  2048test
//
//  Created by 闫榕慧 on 2020/11/17.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
    
    @IBAction func setupGame(sender: UIButton) {
        let game = NumbertailGameController(demension: 4 , threshold: 2048)
        self.present(game, animated: true , completion: nil)
    }

}

