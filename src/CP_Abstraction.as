interface CPAbstraction {
    array<int>@ get_cpTimes();
    int get_cpCount();
    int get_lastCpTime();
}

class WrapPlayerCpInfo : CPAbstraction {
    MLFeed::PlayerCpInfo@ _inner;
    WrapPlayerCpInfo(MLFeed::PlayerCpInfo@ cpInfo) {
        @_inner = cpInfo;
    }
    array<int>@ get_cpTimes() {
        return _inner.cpTimes;
    }
    int get_cpCount() {
        return _inner.cpCount;
    }
    int get_lastCpTime() {
        return _inner.lastCpTime;
    }
}
