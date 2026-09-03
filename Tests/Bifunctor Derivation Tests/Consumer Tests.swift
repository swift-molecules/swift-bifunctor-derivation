import Bifunctor_Derivation
import Testing

@Bifunctor
private struct Pair<First, Second>: Equatable
where First: Equatable, Second: Equatable {
    var first: First
    var second: Second
}

@Test
func `derived bimap obeys identity and independent mapping`() {
    let pair = Pair(first: 21, second: "Blob")

    #expect(pair.bimap({ $0 }, { $0 }) == pair)
    #expect(pair.bimap({ $0 * 2 }, { $0.count }) == Pair(first: 42, second: 4))
}
