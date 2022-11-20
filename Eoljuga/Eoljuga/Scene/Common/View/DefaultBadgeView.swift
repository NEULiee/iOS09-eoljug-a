//
//  DefaultBadgeView.swift
//  Eoljuga
//
//  Created by neuli on 2022/11/19.
//

import UIKit

final class DefaultBadgeView: UIView {

    private let user: User

    // MARK: - Properties

    private lazy var domainLabel = DefaultBadgeLabel(
        text: user.domain.rawValue,
        textColor: user.domain.color
    )

    private lazy var numberLabel = DefaultBadgeLabel(
        text: "7기",
        textColor: .main
    )

    private lazy var camperIDLabel = DefaultBadgeLabel(
        text: user.camperID,
        textColor: .systemGray2
    )

    // MARK: - Initializer

    init(user: User) {
        self.user = user
        super.init(frame: .zero)

        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func configureUI() {
        let badgeStackView = UIStackView(
            arrangedSubviews: [domainLabel, numberLabel, camperIDLabel]
        ).then {
            $0.axis = .horizontal
            $0.distribution = .equalSpacing
            $0.alignment = .fill
            $0.spacing = Constant.space4.cgFloat
        }
        addSubview(badgeStackView)
        badgeStackView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
        }
    }
}