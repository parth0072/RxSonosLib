//
//  NowPlayingViewController.swift
//  RxSonosLib
//
//  Created by Stefan Renne on 13/03/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxSonosLib

class NowPlayingViewController: UIViewController {
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var groupImageView: UIImageView!
    @IBOutlet var groupTrackTitle: UILabel!
    @IBOutlet var groupTrackDescription: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var progressTime: UILabel!
    @IBOutlet var remainingTime: UILabel!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var actionButton: UIButton!
    
    private let disposeBag = DisposeBag()
    internal var router: NowPlayingRouter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupActiveGroupObservable()
        self.setupNowPlayingObservable()
        self.setupVolumeObservables()
        self.setupTransportStateObservable()
        self.setupGroupProgressObservable()
        self.setupImageObservable()
    }
    
    fileprivate func setupActiveGroupObservable() {
        SonosInteractor
            .getActiveGroup()
            .subscribe(onNext: { [weak self] (group) in
                self?.groupNameLabel.text = group?.name
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func setupNowPlayingObservable() {
        self.resetTrack()
        
        SonosInteractor
            .getActiveTrack()
            .subscribe(onNext: { [weak self] (track) in
                guard let track = track else {
                    self?.groupTrackTitle.text = nil
                    self?.groupTrackDescription.text = nil
                    return
                }
                let viewModel = TrackViewModel(track: track)
                self?.groupTrackTitle.text = viewModel.trackTitle
                self?.groupTrackDescription.attributedText = viewModel.trackDescription
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func setupVolumeObservables() {
        SonosInteractor
            .getActiveGroupVolume()
            .filter({ _ in return !self.volumeSlider.isTouchInside })
            .subscribe(onNext: { [weak self] (volume) in
                self?.volumeSlider.value = Float(volume) / 100.0
            })
            .disposed(by: disposeBag)
        
        volumeSlider
            .rx
            .value
            .throttle(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .filter({ _ in return self.volumeSlider.isTouchInside })
            .flatMap({ (newVolume) -> Observable<Void> in
                return SonosInteractor
                    .setActiveGroup(volume: Int(newVolume * 100.0))
            })
            .subscribe(onError: { (error) in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func setupTransportStateObservable() {
        SonosInteractor
         .getActiveTransportState()
         .subscribe(onNext: { [weak self] (state, service) in
            switch state {
                case .paused, .stopped:
                    self?.actionButton.setImage(UIImage(named: "icon_play_large"), for: .normal)
                case .transitioning:
                    self?.actionButton.setImage(UIImage(named: "icon_stop_large"), for: .normal)
                case .playing:
                    let imageName = service.isStreamingService ? "icon_stop_large" : "icon_pause_large"
                    self?.actionButton.setImage(UIImage(named: imageName), for: .normal)
            }
         })
         .disposed(by: disposeBag)
    }
    
    fileprivate func setupGroupProgressObservable() {
        SonosInteractor
            .getActiveGroupProgress()
            .subscribe(onNext: { [weak self] (progress) in
                self?.progressTime.text = progress.timeString
                self?.remainingTime.text = progress.remainingTimeString
                self?.progressView.progress = progress.progress
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func setupImageObservable() {
        SonosInteractor
            .getActiveTrackImage()
            .catchErrorJustReturn(nil)
            .map({ (data) -> UIImage? in
                guard let data = data, let image = UIImage(data: data) else { return nil }
                return image
            })
            .bind(to: groupImageView.rx.image)
            .disposed(by: disposeBag)
    }
    
    fileprivate func resetTrack() {
        self.groupTrackTitle.text = ""
        self.groupTrackDescription.text = ""
        self.progressTime.text = nil
        self.remainingTime.text = nil
        self.progressView.progress = 0
        self.groupImageView.image = nil
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        router?.close()
    }
    
    @IBAction func muteAction(_ sender: UIButton) {
    }
    
    @IBAction func queueAction(_ sender: UIButton) {
        self.router?.continueToQueue()
    }
    
    @IBAction func previousAction(_ sender: UIButton) {
    }
    
    @IBAction func playAction(_ sender: UIButton) {
    }
    
    @IBAction func nextAction(_ sender: UIButton) {
    }
}
