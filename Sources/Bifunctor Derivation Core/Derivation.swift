public import SwiftSyntax
import SwiftSyntaxBuilder

public enum Derivation {
    public static func expansion(of structure: StructDeclSyntax) -> [DeclSyntax] {
        guard
            let generic = structure.genericParameterClause,
            generic.parameters.count == 2
        else { return [] }

        let parameters = Array(generic.parameters)
        let first = parameters[0].name.text
        let second = parameters[1].name.text
        let fields = structure.memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .flatMap(\.bindings)
            .compactMap { binding -> (String, TypeSyntax)? in
                guard
                    let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                    let type = binding.typeAnnotation?.type
                else { return nil }
                return (name, type)
            }

        guard fields.allSatisfy({ field in
            let type = field.1.trimmedDescription
            let identifiers = field.1.tokens(viewMode: .sourceAccurate).map(\.tokenKind)
            return type == first || type == second
                || (!identifiers.contains(.identifier(first))
                    && !identifiers.contains(.identifier(second)))
        }) else { return [] }

        let target = "\(structure.name.text)<MappedFirst, MappedSecond>"
        let arguments = fields.map { field in
            let value =
                field.1.trimmedDescription == first ? "mapFirst(self.\(field.0))"
                : field.1.trimmedDescription == second ? "mapSecond(self.\(field.0))"
                : "self.\(field.0)"
            return "\(field.0): \(value)"
        }.joined(separator: ", ")

        return ["""
            func bimap<MappedFirst, MappedSecond>(
                _ mapFirst: (\(raw: first)) -> MappedFirst,
                _ mapSecond: (\(raw: second)) -> MappedSecond
            ) -> \(raw: target) {
                \(raw: target)(\(raw: arguments))
            }
            """]
    }
}
