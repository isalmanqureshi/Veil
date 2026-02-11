//
//  InboxView.swift
//  Veil
//
//  Created by Salman Qureshi on 2/10/26.
//

import SwiftUI

struct InboxView: View {

    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var vm: InboxViewModel

    init(chatRepo: ChatRepository, requestsRepo: MessageRequestsRepository) {
        _vm = StateObject(wrappedValue: InboxViewModel(chatRepo: chatRepo, requestsRepo: requestsRepo))
    }

    var body: some View {
        VStack(spacing: 0) {

            Picker("", selection: $vm.selectedTab) {
                ForEach(InboxViewModel.Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if vm.selectedTab == .chats {
                if vm.chats.isEmpty {
                    EmptyInboxView()
                } else {
                    List(vm.chats) { thread in
                        Button {
                            coordinator.push(.chat(username: thread.username))
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(thread.username)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(thread.lastPreview)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                // requests list...
                List(vm.requests) { req in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(req.fromUsername).font(.system(size: 16, weight: .semibold))
                        Text(req.previewCiphertext)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        HStack {
                            Button("Ignore") { vm.ignore(req) }
                            Spacer()
                            Button("Accept") {
                                let u = vm.accept(req)
                                coordinator.push(.chat(username: u))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(.plain)
            }
        }
        .onAppear { vm.reload() }
    }
}


#Preview {
    InboxView(chatRepo: MockChatRepository(crypto: MockCryptoService()),
              requestsRepo: MockMessageRequestsRepository(chatRepo: MockChatRepository(crypto: MockCryptoService())))
}
