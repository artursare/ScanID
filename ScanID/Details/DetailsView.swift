//
//  DetailsView.swift
//  ScanID
//
//  Created by Artūrs Āre on 28/09/2021.
//

import SwiftUI

struct DetailsView: View {

    @ObservedObject var vm: DetailsViewModel

    var body: some View {

        VStack{
            Text(vm.loadingText).font(.system(size: 18.0))
            ProgressView()
        }
        .opacity(vm.isLoading ? 1 : 0)
        .padding()

        List(vm.listDataSource, id: \.self) { string in
            Text(string)
        }.padding()
    }
}
