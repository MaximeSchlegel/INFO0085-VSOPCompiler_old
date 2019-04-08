#include "ASTNode.h"
std::string ttos (int token) {
    switch (token) {
        case 260: return "bool";
        case 261: return "int32";
        case 262: return "string";
        case 263: return "unit";
    }
    return "error";
}

ASTNode::ASTNode(int type) {
    this->iType = type;
}

ASTNode::ASTNode(int type, int iValue) {
    this->iType = type;
    this->iValue = iValue;
}

ASTNode::ASTNode(int type, std::string * sValue) {
    this->iType = type;
    this->sValue = sValue;
}

ASTNode::ASTNode(std::string type) {
    this->sType = type;
}

void ASTNode::setPosition(int line, int column) {
    prop l; l.iProp = line;
    prop c; c.iProp = column;
    this->properties.emplace("line", l);
    this->properties.emplace("column", c);
}

void ASTNode::setType(std::string type) {
    prop t; t.sProp = type;
    this->properties.emplace("type", t);
}

std::string ASTNode::getType() const {
    if (this->iType) {
        if (this->iType == 264) {
            this->sValue;
        }
        return ttos(this->iType);
    }
    return "error";
}

void ASTNode::addChild(ASTNode * child) {
    this->children.push_back(child);
}

std::ostream & operator<<(std::ostream & os, const ASTNode & node) {
    // Same order as in vsopc.y
    os << "in print";
    os << node.iType << "/" << node.iValue << "/" << node.sType << "/" << node.sValue << std::endl;

    if (node.iType == 260 or node.iType == 261 or node.iType == 262 or node.iType == 263 or node.iType == 264) {
        os << "const";
        os << node.iType;
        os << node.getType(); // Problem with the const
    } else if (node.sType.compare("program") == 0) {
        os << "[";
        for (auto const& child: node.children) {
            os << *child;
        }
        os << "]";
    } else if (node.sType.compare("class") == 0) {
        os << "Class(" << *(node.children[node.children.size()-2]) << ", " << node.children[1] << ", ";
        for (auto const& child: node.children) {
            if (child->sType.compare("field") == 0) {
                os << *child;
            }
        }
        for (auto const& child: node.children) {
            if (child->sType.compare("method") == 0) {
                os << *child;
            }
        }
        os << ")";
    } else if (node.sType.compare("field") == 0) {
        if (node.children.size() == 4) {
            os << "Field(" << node.children[1] << ", " << node.children[2] << ", " << node.children[0] << ")";
        } else {
            os << "Field(" << node.children[0] << ", " << node.children[1] << ")";
        }
    } else if (node.sType.compare("method") == 0) {
        os << "Method(" << node.children[0] << ", " << node.children[3] << ", " << node.children[1] << ", " << node.children[2] <<")";
    } else if (node.sType.compare("formals") == 0) {
        for (auto const& child: node.children) {
            os << *child;
        }
    } else if (node.sType.compare("formal") == 0) {
        os << node.children[0] << " : " << node.children[1];
    } else if (node.sType.compare("block") == 0) {
        for (auto const& child: node.children) {
            os << *child;
        }
    } else if (node.sType.compare("if") == 0) {
        if (node.children.size() == 3) {
            os << "If(" << node.children[0] << ", " << node.children[1] << ", " << node.children[2] << ")";
        } else {
            os << "If(" << node.children[0] << ", " << node.children[1] << ")";
        }
    } else if (node.sType.compare("while") == 0) {
        os << "While(" << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("let") == 0) {
        if (node.children.size() == 4) {
            os << "Let(" << node.children[0] << ", " << node.children[1] << ", " << node.children[2] << ", " << node.children[3] <<")";
        } else {
            os << "Let(" << node.children[0] << ", " << node.children[1] << ", " << node.children[2] << ")";
        }
    } else if (node.sType.compare("assign") == 0) {
        os << "Assign(" << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("not") == 0) {
        os << "UnOp(not, " << node.children[0] << ")";
    } else if (node.sType.compare("and") == 0) {
        os << "BinOp(and, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("equal") == 0) {
        os << "BinOp(=, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("lower") == 0) {
        os << "BinOp(<, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("lowerequal") == 0) {
        os << "BinOp(<=, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("plus") == 0) {
        os << "BinOp(+, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("minus") == 0) {
        os << "BinOp(-, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("times") == 0) {
        os << "BinOp(*, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("div") == 0) {
        os << "BinOp(/, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("pow") == 0) {
        os << "BinOp(^, " << node.children[0] << ", " << node.children[1] << ")";
    } else if (node.sType.compare("neg") == 0) {
        os << "UnOp(-, " << node.children[0] << ")";
    } else if (node.sType.compare("isnull") == 0) {
        os << "UnOp(isnull, " << node.children[0] << ")";
    } else if (node.sType.compare("call") == 0) {
        os << "Call(" << node.children[0] << ", " << node.children[1] << ", [";
        for (int i = 2; i < node.children.size(); i++) {
            if (i != 2) {
                os << " ,";
            }
            os << node.children[i];
        }
        os << "])";
    } else if (node.sType.compare("new") == 0) {
        os << "New(" << node.children[0] << ")";
    } else if (node.sType.compare("args") == 0) {
        for (auto const& child: node.children) {
            os << *child;
        }
    } else {
        os << node.sType;
    }

    return os;
}

ASTNode::~ASTNode() {
    for(std::vector<ASTNode *>::iterator it=this->children.begin(); it!=this->children.end(); it++) {
        delete (*it);
    }
}
