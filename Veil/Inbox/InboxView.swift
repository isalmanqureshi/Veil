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
            
            header
            
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.privacy) // or settings route
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .semibold))
                }
                .accessibilityLabel("Settings")
            }
        }
        .onAppear { vm.reload() }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 10) {
            Picker("", selection: $vm.selectedTab) {
                Text("Chats").tag(InboxViewModel.Tab.chats)
                Text("Requests").tag(InboxViewModel.Tab.requests)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var content: some View {
        switch vm.selectedTab {
            
        case .chats:
            if vm.chats.isEmpty {
                ScrollView {
                    EmptyInboxView(
                        onStartChat: { coordinator.push(.startChat) },
                        onShareUsername: { coordinator.push(.status) }
                    )
                    .frame(maxWidth: .infinity, minHeight: 420)
                }
                .refreshable { vm.reload() }
            } else {
                List {
                    ForEach(vm.chats) { thread in
                        Button {
                            coordinator.push(.chat(username: thread.username))
                        } label: {
                            ChatRow(username: thread.username, preview: thread.lastPreview)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .refreshable { vm.reload() }
            }
            
        case .requests:
            if vm.requests.isEmpty {
                ScrollView {
                    EmptyRequestsState()
                        .frame(maxWidth: .infinity, minHeight: 420)
                }
                .refreshable { vm.reload() }
            } else {
                
                List {
                    ForEach(vm.requests) { req in
                        Button {
                            coordinator.push(.requestDetails(id: req.id))
                        } label: {
                            RequestRowSummary(request: req)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .refreshable { vm.reload() }
            }
        }
    }
}

#Preview {
    let chatRepo = MockChatRepository(crypto: MockCryptoService())

    return InboxView(
        chatRepo: chatRepo,
        requestsRepo: MockMessageRequestsRepository(chatRepo: chatRepo)
    )
    .environmentObject(AppCoordinator())
}
