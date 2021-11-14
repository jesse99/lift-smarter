//  Created by Jesse Vorisek on 10/8/21.
import SwiftUI

var pickerId = 0

struct PickerEntry: Hashable, Identifiable {
    let name: String
    let color: Color
    let id: Int

    init(_ name: String, _ color: Color) {
        self.name = name
        self.color = color
        self.id = pickerId
        pickerId += 1
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

/// View with a text field and a list. List is populated with items that match the list. User can select an item
/// from the list which then sets the text field (and re-populates the list).
struct PickerView: View {
    typealias Populate = (String) -> [(String, Color)]
    typealias Confirm = (String) -> Void    // called with the result of the pick
    typealias Selected = (String) -> Int?   // scroll returned index into view

    let title: String
    let prompt: String
    let initial: String
    let populate: Populate
    let confirm: Confirm
    let selected: Selected?
    let type: UIKeyboardType
    @State var entries: [PickerEntry]
    @State var value: String
    @Environment(\.presentationMode) private var presentation
    
    init(title: String, prompt: String, initial: String, populate: @escaping Populate, confirm: @escaping Confirm, selected: Selected? = nil, type: UIKeyboardType = .default) {
        self.title = title
        self.prompt = prompt
        self.initial = initial
        self.populate = populate
        self.confirm = confirm
        self.selected = selected
        self.type = type
        self._entries = State(initialValue: populate(initial).map({PickerEntry($0, $1)}))
        self._value = State(initialValue: initial)
    }

    var body: some View {
        VStack() {
            Text(self.title).font(.largeTitle)

            HStack {
                Text(self.prompt).font(.headline)
                TextField("", text: self.$value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(self.type)
                    .disableAutocorrection(true)
            }.padding(.leading)
            Divider().background(Color.black)

            // TODO: This looks better using List but then we don't see any of the content. Need to try this again once ScrollViewReader has matured a bit.
            ScrollViewReader {scrollView in
                ScrollView(.vertical) {
                   // VStack(alignment: .leading) {
                    ForEach(self.entries, id: \.id) {entry in
//                      List(self.entries, id: \.id) {entry in
                            Text(entry.name).font(.headline).foregroundColor(entry.color)
                                .contentShape(Rectangle())  // so we can click within spacer
                                .onTapGesture {self.value = entry.name}
                                .padding(.bottom)
                            Spacer().frame(height: 2)
                        }
                        .onAppear(perform: {self.scrollIntoView(scrollView)})
                        .onChange(of: self.value, perform: {_ in self.onEdit(scrollView)})
                   // }
                }
            }

            HStack {
                Button("Cancel", action: onCancel).font(.callout)
                Spacer()
                Spacer()
                Button("OK", action: onOK).font(.callout)
            }.padding()
        }
    }
    
    private func onEdit(_ scroller: ScrollViewProxy) {
        self.entries = self.populate(self.value).map({PickerEntry($0, $1)})
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollIntoView(scroller)
        }
    }
    
    private func scrollIntoView(_ scroller: ScrollViewProxy) {
        if let select = self.selected, let selection = select(self.value) {
            scroller.scrollTo(self.entries[selection].id, anchor: .center)
        }
    }
    
    private func onCancel() {
        self.presentation.wrappedValue.dismiss()
    }
    
    private func onOK() {
        self.confirm(self.value)
        self.presentation.wrappedValue.dismiss()
    }
}

struct PickerView_Previews: PreviewProvider {
    static let breeds = ["Retrievers (Labrador)", "German Shepherd Dogs", "Retrievers (Golden)", "French Bulldogs", "Bulldogs", "Poodles", "Beagles", "Rottweilers", "Pointers (German Shorthaired)", "Pembroke Welsh Corgis", "Dachshunds", "Yorkshire Terriers", "Australian Shepherds", "Boxers", "Siberian Huskies", "Cavalier King Charles Spaniels", "Great Danes", "Miniature Schnauzers", "Doberman Pinschers", "Shih Tzu", "Boston Terriers", "Havanese", "Bernese Mountain Dogs", "Pomeranians", "Shetland Sheepdogs", "Brittanys", "Spaniels (English Springer)", "Spaniels (Cocker)", "Miniature American Shepherds", "Cane Corso", "Pugs", "Mastiffs", "Border Collies", "Vizslas", "Chihuahuas", "Maltese", "Basset Hounds", "Collies", "Weimaraners", "Newfoundlands", "Belgian Malinois", "Rhodesian Ridgebacks", "Bichons Frises", "West Highland White Terriers", "Shiba Inu", "Retrievers (Chesapeake Bay)", "Akitas", "St. Bernards", "Portuguese Water Dogs", "Spaniels (English Cocker)", "Bloodhounds", "Bullmastiffs", "Papillons", "Soft Coated Wheaten Terriers", "Australian Cattle Dogs", "Scottish Terriers", "Whippets", "Samoyeds", "Dalmatians", "Airedale Terriers", "Bull Terriers", "Wirehaired Pointing Griffons", "Pointers (German Wirehaired)", "Alaskan Malamutes", "Chinese Shar-Pei", "Cardigan Welsh Corgis", "Italian Greyhounds", "Dogues de Bordeaux", "Great Pyrenees", "Old English Sheepdogs", "Giant Schnauzers", "Cairn Terriers", "Greater Swiss Mountain Dogs", "Miniature Pinschers", "Russell Terriers", "Irish Wolfhounds", "Chow Chows", "Lhasa Apsos", "Setters (Irish)", "Chinese Crested", "Coton de Tulear", "Staffordshire Bull Terriers", "Pekingese", "Border Terriers", "American Staffordshire Terriers", "Retrievers (Nova Scotia Duck Tolling)", "Basenjis", "Keeshonden", "Spaniels (Boykin)", "Lagotti Romagnoli", "Rat Terriers", "Bouviers des Flandres", "Norwegian Elkhounds", "Anatolian Shepherd Dogs", "Leonbergers", "Brussels Griffons", "Standard Schnauzers", "Setters (English)", "Fox Terriers (Wire)", "Neapolitan Mastiffs", "Tibetan Terriers", "Norwich Terriers", "Belgian Tervuren", "Retrievers (Flat-Coated)", "Borzois", "Schipperkes", "Toy Fox Terriers", "Japanese Chin", "Silky Terriers", "Welsh Terriers", "Afghan Hounds", "Miniature Bull Terriers", "Setters (Gordon)", "Black Russian Terriers", "Pointers", "Spinoni Italiani", "Tibetan Spaniels", "Parson Russell Terriers", "Irish Terriers", "American Eskimo Dogs", "Beaucerons", "Fox Terriers (Smooth)", "German Pinschers", "American Hairless Terriers", "Salukis", "Belgian Sheepdogs", "Boerboels", "Tibetan Mastiffs", "Treeing Walker Coonhounds", "Spaniels (Welsh Springer)", "Norfolk Terriers", "Icelandic Sheepdogs", "Kerry Blue Terriers", "Spaniels (Clumber)", "Briards", "Bearded Collies", "Xoloitzcuintli", "Bluetick Coonhounds", "English Toy Spaniels", "Manchester Terriers", "Black and Tan Coonhounds", "Australian Terriers", "Redbone Coonhounds", "Spanish Water Dogs", "Wirehaired Vizslas", "Berger Picards", "Portuguese Podengo Pequenos", "Lakeland Terriers", "Scottish Deerhounds", "Affenpinschers", "Bedlington Terriers", "Petits Bassets Griffons Vendeens", "Spaniels (Field)", "Sealyham Terriers", "Setters (Irish Red and White)", "Pumik", "Nederlandse Kooikerhondjes", "Lowchen", "Swedish Vallhunds", "Pulik", "Pharaoh Hounds", "Greyhounds", "Retrievers (Curly-Coated)", "Spaniels (American Water)", "Finnish Lapphunds", "Kuvaszok", "Entlebucher Mountain Dogs", "Glen of Imaal Terriers", "Norwegian Buhunds", "Spaniels (Irish Water)", "Ibizan Hounds", "Otterhounds", "Polish Lowland Sheepdogs", "Dandie Dinmont Terriers", "American English Coonhounds", "Spaniels (Sussex)", "Plott Hounds", "Grand Basset Griffon Vendeens", "Canaan Dogs", "Bergamasco Sheepdogs", "Komondorok", "Pyrenean Shepherds", "Finnish Spitz", "Chinooks", "Cirnechi dell’Etna", "Harriers", "Skye Terriers", "Cesky Terriers", "American Foxhounds", "Azawakhs", "Sloughis", "Norwegian Lundehunds", "English Foxhounds"]
    
    static func populate(_ text: String) -> [(String, Color)] {
        var entries: [(String, Color)] = []
        
        for candidate in breeds {
            if candidate.contains(text) {
                entries.append((candidate, .black))
            }
        }
        
        return entries
    }
    
    static func onConfirm(_ text: String) {
    }
    
    static var previews: some View {
        PickerView(title: "Dog Breeds", prompt: "Breed: ", initial: "Terrier", populate: populate, confirm: onConfirm)
    }
}
