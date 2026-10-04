#if canImport(UIKit)
import UIKit

extension UIControl {

    /// Delivers a tap to the control's targets directly. Package tests run
    /// without an application, and `sendActions(for:)` needs one to deliver
    /// anything.
    func tap() {
        for target in allTargets {
            for action in actions(forTarget: target, forControlEvent: .touchUpInside) ?? [] {
                (target as NSObject).perform(Selector(action), with: self)
            }
        }
    }
}
#endif
