//
//  SavedPaymentMethodRowButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/9/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodRowButtonDelegate: AnyObject {
    func didSelectButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectRemoveButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
    func didSelectUpdateButton(_ button: SavedPaymentMethodRowButton, with paymentMethod: STPPaymentMethod)
}

final class SavedPaymentMethodRowButton: UIView {

    enum State: Equatable {
        case selected
        case unselected
        case editing(allowsRemoval: Bool, allowsUpdating: Bool)
    }

    // MARK: Internal properties
    var state: State = .unselected {
        didSet {
            if oldValue == .selected || oldValue == .unselected {
                previousSelectedState = oldValue
            }

            rowButton.isSelected = isSelected
            rowButton.isEnabled = !isEditing || alternateUpdatePaymentMethodNavigation
            chevronButton.isHidden = !canUpdate || !alternateUpdatePaymentMethodNavigation
            updateButton.isHidden = !canUpdate || alternateUpdatePaymentMethodNavigation
            removeButton.isHidden = !canRemove || alternateUpdatePaymentMethodNavigation
            stackView.isUserInteractionEnabled = isEditing
        }
    }

    var previousSelectedState: State = .unselected

    var isSelected: Bool {
        switch state {
        case .selected:
            return true
        case .unselected, .editing:
            return false
        }
    }

    private var isEditing: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing:
            return true
        }
    }

    private var canUpdate: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing(_, let allowsUpdating):
            return allowsUpdating
        }
    }

    private var canRemove: Bool {
        switch state {
        case .selected, .unselected:
            return false
        case .editing(let allowsRemoval, _):
            return allowsRemoval
        }
    }

    weak var delegate: SavedPaymentMethodRowButtonDelegate?

    // MARK: Internal/private properties
    let paymentMethod: STPPaymentMethod
    private let appearance: PaymentSheet.Appearance

    // MARK: Private views

    private lazy var removeButton: CircularButton = {
        let removeButton = CircularButton(style: .remove, iconColor: .white)
        removeButton.backgroundColor = appearance.colors.danger
        removeButton.isHidden = true
        removeButton.addTarget(self, action: #selector(handleRemoveButtonTapped), for: .touchUpInside)
        return removeButton
    }()

    private lazy var updateButton: CircularButton = {
        let updateButton = CircularButton(style: .edit, iconColor: .white)
        updateButton.backgroundColor = appearance.colors.icon
        updateButton.isHidden = true
        updateButton.addTarget(self, action: #selector(handleUpdateButtonTapped), for: .touchUpInside)
        return updateButton
    }()

    private lazy var chevronButton: RowButton.RightAccessoryButton = {
        let chevronButton = RowButton.RightAccessoryButton(accessoryType: .update, appearance: appearance, didTap: handleUpdateButtonTapped)
        chevronButton.isHidden = true
        return chevronButton
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.makeRowButtonContentStackView(arrangedSubviews: [chevronButton, updateButton, removeButton])
        // margins handled by the `RowButton`
        stackView.directionalLayoutMargins = .zero
        stackView.isUserInteractionEnabled = isEditing
        return stackView
    }()

    private lazy var rowButton: RowButton = {
        let button: RowButton = .makeForSavedPaymentMethod(paymentMethod: paymentMethod, appearance: appearance, rightAccessoryView: stackView, didTap: handleRowButtonTapped)

        return button
    }()

    private let alternateUpdatePaymentMethodNavigation: Bool

    init(paymentMethod: STPPaymentMethod,
         appearance: PaymentSheet.Appearance,
         alternateUpdatePaymentMethodNavigation: Bool = false) {
        self.paymentMethod = paymentMethod
        self.appearance = appearance
        self.alternateUpdatePaymentMethodNavigation = alternateUpdatePaymentMethodNavigation
        super.init(frame: .zero)

        addAndPinSubview(rowButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Tap handlers
    @objc private func handleUpdateButtonTapped() {
        delegate?.didSelectUpdateButton(self, with: paymentMethod)
    }

    @objc private func handleRemoveButtonTapped() {
        delegate?.didSelectRemoveButton(self, with: paymentMethod)
    }

    @objc private func handleRowButtonTapped(_: RowButton) {
        if alternateUpdatePaymentMethodNavigation && isEditing {
            delegate?.didSelectUpdateButton(self, with: paymentMethod)
        }
        else {
            state = .selected
            delegate?.didSelectButton(self, with: paymentMethod)
        }
    }
}
