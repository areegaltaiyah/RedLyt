
//  SplashSc.swift
//  RedLyt
//
//  Created by Jasmin Alshwayhi on 23/08/1447 AH.
//


import SwiftUI
struct SplashSc: View {
    var body: some View {
        
                ZStack {

                  Color.bgS.opacity(100)
                    .ignoresSafeArea()
                    

                    Circle()
                        .stroke(Color.bgcc.opacity(80), lineWidth: 20)
                        .frame(width: 473, height: 459)
                        .blur(radius: 30
                        )
                        .offset(x: 60, y: 170)

                    Circle()
                        .stroke(Color.bgcc.opacity(80), lineWidth: 20)
                        .frame(width: 473, height: 459)
                        .blur(radius: 30
                        )
                        .offset(x: 120, y: -300)

                    Circle()
                        .stroke(Color.bgcc.opacity(80), lineWidth: 20)
                        .frame(width: 473, height: 459)
                        .blur(radius: 30
                        )
                        .offset(x: -300, y: -100)



                    VStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350)
                            .offset(x: 40,y:20)
                        ZStack() {
                            
                            
                            
                            Image("B")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 400 ,height: 350)
                                .offset(x: -28, y: 125)
                            
                            
                            Image("A")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 400,height: 350)
                                .offset(x: -20, y: 120)
                            
                            
                            
                            
                            Image("C")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160,height: 200)
                                .offset(x: 130, y: -60)
                        }
                    }
                    }
                }
            }
        


        
        
        
        

#Preview {
    SplashSc()
}
