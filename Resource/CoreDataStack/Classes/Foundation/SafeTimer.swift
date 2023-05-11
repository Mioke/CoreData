//
//  SeaSafeTimer.swift
//  SeaFoundation
//
//  Created by Thanh Quach on 12/8/17.
//  Copyright © 2017 Sea Ltd. All rights reserved.
//

import Foundation

public protocol SafeTimerDelegate: AnyObject {

    func safeTimerDidTrigger(_ safeTimer: SafeTimer)

}

public typealias SafeTimerInvokeBlock = (_ timer: SafeTimer) -> Void

open class SafeTimer {

    public weak var delegate: SafeTimerDelegate?
    private(set) var invokeBlock: SafeTimerInvokeBlock?

    fileprivate var timer: Timer?
    fileprivate var timerTarget: SeaTimerTarget

    public init() {
        timerTarget = SeaTimerTarget()
        timerTarget.delegate = self
    }

    deinit {
        invalidate()
    }

    open var isValid: Bool {
        return timer?.isValid ?? false
    }

    /// Schedule with interval for invoke
    ///
    /// - Parameters:
    ///   - timeInterval: The interval schedule invoke
    ///   - repeats: isReapts
    ///   - userInfo: Supply more information
    ///   - invokeBlock: Invoke schedule in block. But SafeTimer have delegate it call both invoke block and delegate
    open func schedule(timeInterval: TimeInterval,
                       repeats: Bool = false,
                       userInfo: Any? = nil,
                       invokeBlock: SafeTimerInvokeBlock? = nil) {

        invalidate()
        self.invokeBlock = invokeBlock
        timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                     target: timerTarget,
                                     selector: #selector(SeaTimerTarget.didTriggerTimer(_:)),
                                     userInfo: userInfo,
                                     repeats: repeats)
    }

    open func invalidate() {
        timer?.invalidate()
        self.invokeBlock = nil
        timer = nil
    }
}

extension SafeTimer: SafeTimerTargetDelegate {

    fileprivate func timerTargetDidTriggerTimer(_ timer: Timer) {

        if !timer.isValid {
            self.timer = nil
        }
        DispatchQueue.main.async { [weak self] in
            guard let me = self else { return }

            me.delegate?.safeTimerDidTrigger(me)
            me.invokeBlock?(me)
        }
    }
}

// MARK: - TimerTarget

fileprivate protocol SafeTimerTargetDelegate: AnyObject {
    func timerTargetDidTriggerTimer(_ timer: Timer)
}

fileprivate class SeaTimerTarget {

    weak var delegate: SafeTimerTargetDelegate?

    @objc func didTriggerTimer(_ timer: Timer) {
        delegate?.timerTargetDidTriggerTimer(timer)
    }
}
